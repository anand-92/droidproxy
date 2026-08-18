import Foundation

/// Keeps personal Max and org Claude seats on the same email from clobbering
/// each other. CLIProxyAPI always writes `claude-{email}.json`; after the file
/// is complete we rename it to `claude-{email}-{organization_uuid}.json` so the
/// next `-claude-login` can create a fresh canonical file for the other org.
enum ClaudeAuthSeatFiles {
    struct OrganizationFields: Equatable {
        var uuid: String?
        var name: String?

        var hasSeatIdentity: Bool {
            uuid != nil || name != nil
        }
    }

    static func organizationFields(from json: [String: Any]) -> OrganizationFields {
        var uuid = nonemptyString(json["organization_uuid"])
        var name = nonemptyString(json["organization_name"])
        if (uuid == nil || name == nil), let org = json["organization"] as? [String: Any] {
            if uuid == nil {
                uuid = nonemptyString(org["uuid"]) ?? nonemptyString(org["organization_uuid"])
            }
            if name == nil {
                name = nonemptyString(org["name"]) ?? nonemptyString(org["organization_name"])
            }
        }
        return OrganizationFields(uuid: uuid, name: name)
    }

    /// Settings / quota suffix after the email: `Personal Max`, `{org} (Team)`,
    /// or the raw organization name when we cannot classify the plan.
    ///
    /// CLIProxyAPI auth files have no subscription field today. Prefer explicit
    /// `organization_type` / `rate_limit_tier` when present; otherwise use a
    /// conservative name heuristic (person-style names → Personal Max; ALL-CAPS
    /// or company-suffix names → Team). Ambiguous names are shown as-is.
    static func seatDisplayLabel(email: String?, json: [String: Any]) -> String? {
        let fields = organizationFields(from: json)
        if let fromPlan = labelFromPlanHints(json: json, organizationName: fields.name) {
            return fromPlan
        }
        return seatDisplayLabel(email: email, organizationName: fields.name)
    }

    static func seatDisplayLabel(email: String?, organizationName: String?) -> String? {
        guard let name = organizationName else { return nil }
        if looksLikePersonalOrganizationName(name, email: email) {
            return "Personal Max"
        }
        if looksLikeTeamOrganizationName(name) {
            return "\(name) (Team)"
        }
        return name
    }

    static func canonicalFilename(email: String) -> String {
        "claude-\(email).json"
    }

    static func isCanonicalClaudeEmailFile(_ filename: String, email: String) -> Bool {
        filename == canonicalFilename(email: email)
    }

    /// UUID when present (stable); otherwise a filesystem-safe organization name.
    static func uniqueFilename(email: String, fields: OrganizationFields) -> String? {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return nil }
        if let suffix = filenameSafeSuffix(fields.uuid) ?? filenameSafeSuffix(fields.name) {
            return "claude-\(email)-\(suffix).json"
        }
        return nil
    }

    /// Renames complete `claude-{email}.json` files that carry org identity.
    /// Incomplete / empty / non-Claude files are left untouched so a mid-write
    /// from CLIProxyAPI can be retried on the next directory-watcher tick.
    @discardableResult
    static func migrateCanonicalFiles(in directory: URL) -> [URL] {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
        } catch {
            NSLog("[ClaudeAuthSeatFiles] Failed to list %@: %@", directory.path, error.localizedDescription)
            return []
        }

        var destinations: [URL] = []
        for file in files where file.pathExtension.lowercased() == "json" {
            if let dest = migrateFile(at: file) {
                destinations.append(dest)
            }
        }
        return destinations
    }

    @discardableResult
    static func migrateFile(at url: URL) -> URL? {
        let filename = url.lastPathComponent
        guard filename.hasPrefix("claude-"), filename.lowercased().hasSuffix(".json") else {
            return nil
        }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let size = fileSize(at: url)
        guard size > 0 else {
            NSLog("[ClaudeAuthSeatFiles] Skipping empty or mid-write file %@", filename)
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              type.lowercased() == "claude" else {
            return nil
        }

        guard let email = nonemptyString(json["email"]) else { return nil }

        let fields = organizationFields(from: json)
        guard let destName = uniqueFilename(email: email, fields: fields), destName != filename else {
            return nil
        }

        // Canonical `claude-{email}.json` always moves once org identity exists.
        // Already-suffixed workaround names (`claude-{email}-kaikaku.json`) move
        // onto the stable UUID filename so a later re-auth refreshes that file
        // instead of leaving a sibling.
        let isCanonical = isCanonicalClaudeEmailFile(filename, email: email)
        if !isCanonical && fields.uuid == nil {
            return nil
        }

        let dest = url.deletingLastPathComponent().appendingPathComponent(destName)
        do {
            try data.write(to: dest, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: dest.path)
            if url.standardizedFileURL != dest.standardizedFileURL {
                try FileManager.default.removeItem(at: url)
            }
            NSLog("[ClaudeAuthSeatFiles] Renamed %@ -> %@", filename, destName)
            return dest
        } catch {
            NSLog("[ClaudeAuthSeatFiles] Failed to rename %@: %@", filename, error.localizedDescription)
            return nil
        }
    }

    // MARK: - Plan / name classification

    private static let companySuffixes: Set<String> = [
        "inc", "inc.", "llc", "ltd", "ltd.", "corp", "corporation",
        "gmbh", "ag", "plc", "company", "co", "co.", "team", "labs",
        "studio", "technologies", "tech", "limited"
    ]

    private static let nameParticles: Set<String> = [
        "van", "von", "de", "da", "del", "della", "di", "la", "le", "du",
        "st", "st.", "der", "den", "bin", "al"
    ]

    private static func labelFromPlanHints(json: [String: Any], organizationName: String?) -> String? {
        let hints = planHintStrings(from: json)
        guard !hints.isEmpty else { return nil }

        if hints.contains(where: isPersonalMaxHint) {
            return "Personal Max"
        }
        if hints.contains(where: { isEnterpriseHint($0) }) {
            if let organizationName { return "\(organizationName) (Enterprise)" }
            return "Enterprise"
        }
        if hints.contains(where: isTeamHint) {
            if let organizationName { return "\(organizationName) (Team)" }
            return "Team"
        }
        if hints.contains(where: isPersonalProHint) {
            return "Personal Pro"
        }
        return nil
    }

    private static func planHintStrings(from json: [String: Any]) -> [String] {
        var values: [String] = []
        let keys = [
            "organization_type", "rate_limit_tier", "billing_type",
            "plan", "subscription_type", "account_type"
        ]
        for key in keys {
            if let value = nonemptyString(json[key]) {
                values.append(value)
            }
        }
        if let org = json["organization"] as? [String: Any] {
            for key in keys + ["type"] {
                if let value = nonemptyString(org[key]) {
                    values.append(value)
                }
            }
        }
        return values
    }

    private static func isPersonalMaxHint(_ raw: String) -> Bool {
        let value = raw.lowercased()
        return value.contains("claude_max")
            || value == "max"
            || value.contains("default_claude_max")
    }

    private static func isPersonalProHint(_ raw: String) -> Bool {
        let value = raw.lowercased()
        return value.contains("claude_pro") || value == "pro" || value == "claude_pro"
    }

    private static func isTeamHint(_ raw: String) -> Bool {
        let value = raw.lowercased()
        return value.contains("claude_team") || value == "team" || value.contains("team_plan")
    }

    private static func isEnterpriseHint(_ raw: String) -> Bool {
        let value = raw.lowercased()
        return value.contains("enterprise")
    }

    static func looksLikePersonalOrganizationName(_ name: String, email: String?) -> Bool {
        if let email, looksLikeEmailPersonalOrganization(name, email: email) {
            return true
        }
        return looksLikePersonDisplayName(name)
    }

    /// Claude often names the personal org `{email}'s Organization`.
    static func looksLikeEmailPersonalOrganization(_ name: String, email: String) -> Bool {
        let lowered = name.lowercased()
        let emailLower = email.lowercased()
        if lowered == "\(emailLower)'s organization" || lowered == "\(emailLower)’s organization" {
            return true
        }
        let local = String(emailLower.split(separator: "@").first ?? "")
        if !local.isEmpty && (lowered == "\(local)'s organization" || lowered == "\(local)’s organization") {
            return true
        }
        return false
    }

    /// Anthropic's personal Max org is often the user's display name ("Josef Chen").
    static func looksLikePersonDisplayName(_ name: String) -> Bool {
        let parts = name.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard (2...4).contains(parts.count) else { return false }

        var contentWords = 0
        for part in parts {
            let lower = part.lowercased()
            if companySuffixes.contains(lower) { return false }
            if nameParticles.contains(lower) { continue }
            guard looksLikeNameToken(part) else { return false }
            contentWords += 1
        }
        return contentWords >= 2
    }

    static func looksLikeTeamOrganizationName(_ name: String) -> Bool {
        if looksLikePersonDisplayName(name) { return false }
        let parts = name.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !parts.isEmpty else { return false }
        if parts.contains(where: { companySuffixes.contains($0.lowercased()) }) {
            return true
        }
        if parts.count == 1 {
            let token = parts[0]
            let letters = token.filter(\.isLetter)
            let hasLower = token.contains(where: { $0.isLowercase })
            if letters.count >= 3 && !hasLower && token == token.uppercased() {
                return true
            }
        }
        return false
    }

    private static func looksLikeNameToken(_ token: String) -> Bool {
        guard let first = token.first, first.isUppercase else { return false }
        guard token.contains(where: { $0.isLowercase }) else { return false }
        return token.allSatisfy { $0.isLetter || $0 == "-" || $0 == "'" }
    }

    // MARK: - Helpers

    static func nonemptyString(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func filenameSafeSuffix(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let mapped = raw.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar)
                || scalar == "-" || scalar == "." || scalar == "_" {
                return Character(scalar)
            }
            return "-"
        }
        var result = String(mapped)
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-."))
        return result.isEmpty ? nil : result
    }

    private static func fileSize(at url: URL) -> Int {
        // Prefer attributesOfItem — URL resource values can stay stale after a
        // mid-write grows the file on the same URL instance.
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? NSNumber {
            return size.intValue
        }
        return 0
    }
}
