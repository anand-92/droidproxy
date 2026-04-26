import Combine
import Foundation

struct OAuthUsageWindow: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let usedPercent: Double?
    let resetText: String?

    var remainingPercent: Double? {
        guard let usedPercent else { return nil }
        return max(0, 100 - usedPercent)
    }
}

struct OAuthAccountUsage: Identifiable, Equatable {
    let id: String
    let provider: ServiceType
    let email: String
    var isLoading = false
    var windows: [OAuthUsageWindow] = []
    var error: String?
    var updatedAt: Date?
}

final class OAuthUsageTracker: ObservableObject, @unchecked Sendable {
    @Published private(set) var accounts: [OAuthAccountUsage] = []
    @Published private(set) var isRefreshing = false

    func refresh(accounts authAccounts: [AuthAccount]) {
        let enabledAccounts = authAccounts.filter { !$0.isDisabled && !$0.isExpired }
        guard !enabledAccounts.isEmpty else {
            DispatchQueue.main.async {
                self.accounts = []
                self.isRefreshing = false
            }
            return
        }

        DispatchQueue.main.async {
            self.isRefreshing = true
            self.accounts = enabledAccounts.map {
                OAuthAccountUsage(id: $0.id, provider: $0.type, email: $0.displayName, isLoading: true)
            }
        }

        Task.detached(priority: .utility) { [enabledAccounts] in
            let results = await withTaskGroup(of: OAuthAccountUsage.self) { group in
                for account in enabledAccounts {
                    group.addTask {
                        await Self.fetchUsage(for: account)
                    }
                }

                var values: [OAuthAccountUsage] = []
                for await result in group {
                    values.append(result)
                }
                return values.sorted {
                    if $0.provider.rawValue == $1.provider.rawValue {
                        return $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending
                    }
                    return $0.provider.rawValue < $1.provider.rawValue
                }
            }

            await MainActor.run {
                self.accounts = results
                self.isRefreshing = false
            }
        }
    }

    private static func fetchUsage(for account: AuthAccount) async -> OAuthAccountUsage {
        switch account.type {
        case .codex:
            return await fetchCodexUsage(for: account)
        case .gemini:
            return await fetchGeminiUsage(for: account)
        case .claude:
            return failedAccount(account, "Usage tracking is not enabled for this provider")
        }
    }

    private static func fetchCodexUsage(for account: AuthAccount) async -> OAuthAccountUsage {
        guard let token = stringValue("access_token", from: account.filePath) else {
            return failedAccount(account, "Missing access token")
        }
        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else {
            return failedAccount(account, "Invalid usage endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return await fetchJSONUsage(account: account, request: request) { json in
            parseGenericWindows(json)
        }
    }

    private static func fetchGeminiUsage(for account: AuthAccount) async -> OAuthAccountUsage {
        guard let token = stringValue("access_token", from: account.filePath) else {
            return failedAccount(account, "Missing access token")
        }
        guard let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota") else {
            return failedAccount(account, "Invalid quota endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let projectId = stringValue("project_id", from: account.filePath), !projectId.isEmpty {
            request.httpBody = Data("{\"project\":\"\(projectId)\"}".utf8)
        } else {
            request.httpBody = Data("{}".utf8)
        }

        return await fetchJSONUsage(account: account, request: request) { json in
            parseGeminiWindows(json)
        }
    }

    private static func fetchJSONUsage(
        account: AuthAccount,
        request: URLRequest,
        parse: (Any) -> [OAuthUsageWindow]
    ) async -> OAuthAccountUsage {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return failedAccount(account, "No HTTP response")
            }
            guard (200..<300).contains(http.statusCode) else {
                return failedAccount(account, "Usage API returned \(http.statusCode)")
            }
            let json = try JSONSerialization.jsonObject(with: data)
            let windows = parse(json)
            guard !windows.isEmpty else {
                return failedAccount(account, "Usage response did not include quota windows")
            }
            return OAuthAccountUsage(
                id: account.id,
                provider: account.type,
                email: account.displayName,
                windows: windows,
                updatedAt: Date()
            )
        } catch {
            return failedAccount(account, error.localizedDescription)
        }
    }

    private static func failedAccount(_ account: AuthAccount, _ message: String) -> OAuthAccountUsage {
        OAuthAccountUsage(
            id: account.id,
            provider: account.type,
            email: account.displayName,
            error: message,
            updatedAt: Date()
        )
    }

    private static func stringValue(_ key: String, from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func parseGeminiWindows(_ object: Any) -> [OAuthUsageWindow] {
        guard let root = object as? [String: Any],
              let buckets = root["buckets"] as? [[String: Any]] else {
            return parseGenericWindows(object)
        }

        let grouped = Dictionary(grouping: buckets) { bucket in
            (bucket["modelId"] as? String) ?? "Gemini"
        }

        return grouped.compactMap { model, buckets -> OAuthUsageWindow? in
            let lowestRemaining = buckets.compactMap { numberValue($0["remainingFraction"]) }.min()
            guard let remaining = lowestRemaining else { return nil }
            let resetText = buckets.compactMap { Self.resetText(from: $0) }.first
            return OAuthUsageWindow(
                title: model.replacingOccurrences(of: "models/", with: ""),
                usedPercent: max(0, min(100, 100 - (remaining * 100))),
                resetText: resetText
            )
        }
        .sorted { $0.title < $1.title }
    }

    private static func parseGenericWindows(_ object: Any) -> [OAuthUsageWindow] {
        let dictionaries = flattenDictionaries(object)
        var windows: [OAuthUsageWindow] = []

        for dictionary in dictionaries {
            guard let title = windowTitle(from: dictionary),
                  !windows.contains(where: { $0.title == title }) else {
                continue
            }
            let percent = percentValue(from: dictionary)
            let reset = resetText(from: dictionary)
            if percent != nil || reset != nil {
                windows.append(OAuthUsageWindow(title: title, usedPercent: percent, resetText: reset))
            }
        }

        return windows.sorted { windowRank($0.title) < windowRank($1.title) }
    }

    private static func flattenDictionaries(_ value: Any) -> [[String: Any]] {
        if let dictionary = value as? [String: Any] {
            return [dictionary] + dictionary.values.flatMap(flattenDictionaries)
        }
        if let array = value as? [Any] {
            return array.flatMap(flattenDictionaries)
        }
        return []
    }

    private static func windowTitle(from dictionary: [String: Any]) -> String? {
        let joined = dictionary.map { "\($0.key):\($0.value)" }.joined(separator: " ").lowercased()
        if joined.contains("5h") || joined.contains("5-hour") || joined.contains("five") {
            return "5-hour"
        }
        if joined.contains("weekly") || joined.contains("week") || joined.contains("7d") {
            return "Weekly"
        }
        if joined.contains("full") || joined.contains("premium") || joined.contains("paid") {
            return "Full"
        }
        if joined.contains("standard") || joined.contains("session") {
            return "Session"
        }
        return nil
    }

    private static func percentValue(from dictionary: [String: Any]) -> Double? {
        for (key, value) in dictionary {
            let lower = key.lowercased()
            guard lower.contains("percent") || lower.contains("usage") || lower.contains("used") || lower.contains("fraction") else {
                continue
            }
            guard let number = numberValue(value) else { continue }
            return number <= 1 ? number * 100 : number
        }
        return nil
    }

    private static func resetText(from dictionary: [String: Any]) -> String? {
        for (key, value) in dictionary where key.lowercased().contains("reset") {
            if let string = value as? String, !string.isEmpty {
                if let date = ISO8601DateFormatter().date(from: string) {
                    return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
                }
                return string
            }
            if let number = numberValue(value) {
                let date = Date(timeIntervalSince1970: number > 10_000_000_000 ? number / 1000 : number)
                return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
            }
        }
        return nil
    }

    private static func numberValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String {
            return Double(value.replacingOccurrences(of: "%", with: ""))
        }
        return nil
    }

    private static func windowRank(_ title: String) -> Int {
        switch title {
        case "5-hour": return 0
        case "Session": return 1
        case "Weekly": return 2
        case "Full": return 3
        default: return 9
        }
    }
}
