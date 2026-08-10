import AppKit
import Combine
import Foundation

/// A model exposed by the local Copilot API gateway. The gateway obtains this
/// catalog from the signed-in Copilot account, so policies and plan-specific
/// availability are respected instead of being hard-coded in DroidProxy.
struct CopilotModelDescriptor: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let displayName: String
    let maxOutputTokens: Int
    let maxContextLimit: Int?
    let supportsVision: Bool
    let reasoningEfforts: [String]

    init(
        id: String,
        displayName: String,
        maxOutputTokens: Int,
        maxContextLimit: Int?,
        supportsVision: Bool,
        reasoningEfforts: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.maxOutputTokens = maxOutputTokens
        self.maxContextLimit = maxContextLimit
        self.supportsVision = supportsVision
        self.reasoningEfforts = reasoningEfforts
    }

    /// Produces a stable Factory custom-model ID suffix without assuming that
    /// Copilot model identifiers use only alphanumeric characters.
    var identifierSlug: String {
        let components = id.lowercased().map { character in
            character.isLetter || character.isNumber ? String(character) : "-"
        }
        let collapsed = components.joined()
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "model" : collapsed
    }
}

/// Persists the last account-specific model catalog and at most three chosen
/// models. Factory custom-model entries are generated only from this selection.
enum CopilotModelPreferences {
    static let selectedModelIDsKey = "copilotSelectedModelIDs"
    static let cachedModelsKey = "copilotCachedModels"
    static let maximumSelectedModels = 3

    static var selectedModelIDs: [String] {
        normalizedModelIDs(UserDefaults.standard.stringArray(forKey: selectedModelIDsKey) ?? [])
    }

    static var cachedModels: [CopilotModelDescriptor] {
        guard let data = UserDefaults.standard.data(forKey: cachedModelsKey),
              let models = try? JSONDecoder().decode([CopilotModelDescriptor].self, from: data) else {
            return []
        }
        return models
    }

    static var selectedModels: [CopilotModelDescriptor] {
        let cachedByID = Dictionary(uniqueKeysWithValues: cachedModels.map { ($0.id, $0) })
        return selectedModelIDs.map { id in
            cachedByID[id] ?? CopilotModelDescriptor(
                id: id,
                displayName: id,
                maxOutputTokens: 128_000,
                maxContextLimit: nil,
                supportsVision: false,
                reasoningEfforts: []
            )
        }
    }

    static func saveSelectedModelIDs(_ ids: [String]) {
        UserDefaults.standard.set(normalizedModelIDs(ids), forKey: selectedModelIDsKey)
    }

    static func saveCachedModels(_ models: [CopilotModelDescriptor]) {
        guard let data = try? JSONEncoder().encode(models) else {
            NSLog("[Copilot] Failed to encode cached model catalog")
            return
        }
        UserDefaults.standard.set(data, forKey: cachedModelsKey)
    }

    static func normalizedModelIDs(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.compactMap { rawID in
            let id = rawID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, seen.insert(id).inserted else { return nil }
            return id
        }
        .prefix(maximumSelectedModels)
        .map { $0 }
    }
}

enum CopilotGatewayError: LocalizedError {
    case nodeNotInstalled
    case notAuthenticated
    case gatewayNotRunning
    case failedToStart(String)
    case authenticationFailed
    case invalidModelResponse
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .nodeNotInstalled:
            return "Node.js 20 or later is required for GitHub Copilot support. Install Node.js, then try again."
        case .notAuthenticated:
            return "Connect GitHub Copilot before starting the local Copilot gateway."
        case .gatewayNotRunning:
            return "The local Copilot gateway is not running. Start it, then refresh models."
        case .failedToStart(let detail):
            return "Could not start the local Copilot gateway: \(detail)"
        case .authenticationFailed:
            return "GitHub Copilot authentication did not complete. Please try again."
        case .invalidModelResponse:
            return "The Copilot gateway returned an invalid model catalog."
        case .requestFailed:
            return "Could not load models from the local Copilot gateway."
        }
    }
}

/// Manages the independently packaged Copilot gateway. Mainline CLIProxyAPI
/// does not implement GitHub Copilot, so DroidProxy launches the maintained
/// `@jeffreycao/copilot-api` gateway on a localhost-only port.
final class CopilotGatewayManager: ObservableObject {
    static let gatewayPort = 8319
    static let gatewayBaseURL = "http://127.0.0.1:\(gatewayPort)/v1"
    static let packageSpecifier = "@jeffreycao/copilot-api@2.1.0"
    private static let factoryReasoningEffortOrder = [
        "none", "minimal", "low", "medium", "high", "xhigh", "max"
    ]
    private static let factoryReasoningEfforts = Set(factoryReasoningEffortOrder)
    private static let supportedGatewayEndpoints: Set<String> = [
        "/chat/completions", "/responses", "ws:/responses", "/v1/messages"
    ]

    private enum ProcessTiming {
        static let gracefulTerminationTimeout: TimeInterval = 2.0
        static let terminationPollInterval: TimeInterval = 0.05
    }

    static let dataDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".droidproxy")
        .appendingPathComponent("copilot-api")
    static let credentialsURL = dataDirectory.appendingPathComponent("github_token")

    @Published private(set) var isRunning = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var availableModels: [CopilotModelDescriptor]
    @Published private(set) var lastError: String?

    private var gatewayProcess: Process?
    private var authenticationProcess: Process?
    private var gatewayOutputPipes: [Pipe] = []
    private var authenticationOutputPipes: [Pipe] = []
    private var isolatedProcessGroups = Set<pid_t>()

    init() {
        availableModels = CopilotModelPreferences.cachedModels
    }

    var hasCredentials: Bool {
        Self.hasCredentials
    }

    static var hasCredentials: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: credentialsURL.path),
              let size = attributes[.size] as? NSNumber else {
            return false
        }
        return size.intValue > 0
    }

    func start(completion: ((Bool) -> Void)? = nil) {
        if let gatewayProcess, gatewayProcess.isRunning {
            isRunning = true
            completion?(true)
            return
        }

        guard hasCredentials else {
            isRunning = false
            lastError = CopilotGatewayError.notAuthenticated.localizedDescription
            completion?(false)
            return
        }

        guard let npxURL = Self.npxExecutableURL() else {
            isRunning = false
            lastError = CopilotGatewayError.nodeNotInstalled.localizedDescription
            completion?(false)
            return
        }

        let process = Process()
        process.executableURL = npxURL
        process.arguments = [
            "--yes",
            Self.packageSpecifier,
            "--api-home=\(Self.dataDirectory.path)",
            "start",
            "--port",
            String(Self.gatewayPort)
        ]
        process.environment = Self.gatewayEnvironment()
        gatewayOutputPipes = attachOutputPipes(to: process) { _ in }

        process.terminationHandler = { [weak self, weak process] terminatedProcess in
            DispatchQueue.main.async {
                guard self?.gatewayProcess === process else { return }
                self?.gatewayProcess = nil
                self?.isRunning = false
                self?.clearGatewayOutputPipes()
                if terminatedProcess.terminationStatus != 0 {
                    self?.lastError = "The local Copilot gateway stopped unexpectedly."
                }
            }
        }

        do {
            try process.run()
            isolateProcessGroup(for: process)
            gatewayProcess = process
            isRunning = true
            lastError = nil
            NSLog("[Copilot] Started local gateway on port %d", Self.gatewayPort)
            completion?(true)
        } catch {
            isRunning = false
            clearGatewayOutputPipes()
            lastError = CopilotGatewayError.failedToStart(error.localizedDescription).localizedDescription
            completion?(false)
        }
    }

    func stop() {
        if let gatewayProcess {
            terminate(gatewayProcess)
        }
        gatewayProcess = nil
        isRunning = false
        clearGatewayOutputPipes()

        cancelAuthentication()
    }

    func cancelAuthentication() {
        guard let authenticationProcess else { return }
        terminate(authenticationProcess)
        self.authenticationProcess = nil
        isAuthenticating = false
        clearAuthenticationOutputPipes()
    }

    /// Starts Copilot's device-code flow. The gateway owns the token file and
    /// keeps it mode 0600; DroidProxy never reads or logs its contents.
    func startAuthentication(
        onDeviceCode: @escaping (_ code: String, _ verificationURL: URL) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard !isAuthenticating else { return }
        guard let npxURL = Self.npxExecutableURL() else {
            completion(.failure(CopilotGatewayError.nodeNotInstalled))
            return
        }

        let process = Process()
        process.executableURL = npxURL
        process.arguments = [
            "--yes",
            Self.packageSpecifier,
            "--api-home=\(Self.dataDirectory.path)",
            "auth",
            "login",
            "--provider",
            "copilot"
        ]
        process.environment = Self.gatewayEnvironment()

        let promptCapture = DeviceCodeCapture(onDeviceCode: onDeviceCode)
        authenticationOutputPipes = attachOutputPipes(to: process) { text in
            promptCapture.append(text)
        }

        process.terminationHandler = { [weak self, weak process] terminatedProcess in
            DispatchQueue.main.async {
                guard self?.authenticationProcess === process else { return }
                self?.authenticationProcess = nil
                self?.isAuthenticating = false
                self?.clearAuthenticationOutputPipes()
                if terminatedProcess.terminationStatus == 0, Self.hasCredentials {
                    self?.lastError = nil
                    NotificationCenter.default.post(name: .authDirectoryChanged, object: nil)
                    completion(.success(()))
                } else {
                    self?.lastError = CopilotGatewayError.authenticationFailed.localizedDescription
                    completion(.failure(CopilotGatewayError.authenticationFailed))
                }
            }
        }

        do {
            try process.run()
            isolateProcessGroup(for: process)
            authenticationProcess = process
            isAuthenticating = true
            lastError = nil
            NSLog("[Copilot] Started GitHub device authentication")
        } catch {
            clearAuthenticationOutputPipes()
            completion(.failure(CopilotGatewayError.failedToStart(error.localizedDescription)))
        }
    }

    func refreshAvailableModels(completion: @escaping (Result<[CopilotModelDescriptor], Error>) -> Void) {
        guard isRunning else {
            completion(.failure(CopilotGatewayError.gatewayNotRunning))
            return
        }

        guard let url = URL(string: "\(Self.gatewayBaseURL)/models") else {
            completion(.failure(CopilotGatewayError.requestFailed))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let result: Result<[CopilotModelDescriptor], Error>
            if error != nil {
                result = .failure(CopilotGatewayError.requestFailed)
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                result = .failure(CopilotGatewayError.requestFailed)
            } else if let data, let models = Self.parseModels(from: data) {
                result = .success(models)
            } else {
                result = .failure(CopilotGatewayError.invalidModelResponse)
            }

            DispatchQueue.main.async {
                switch result {
                case .success(let models):
                    self?.availableModels = models
                    self?.lastError = nil
                    CopilotModelPreferences.saveCachedModels(models)
                    completion(.success(models))
                case .failure(let error):
                    self?.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    @discardableResult
    func disconnect() -> Bool {
        stop()
        do {
            try FileManager.default.removeItem(at: Self.credentialsURL)
            clearCachedModelCatalog()
            NotificationCenter.default.post(name: .authDirectoryChanged, object: nil)
            return true
        } catch CocoaError.fileNoSuchFile {
            clearCachedModelCatalog()
            return true
        } catch {
            lastError = "Could not remove GitHub Copilot credentials."
            return false
        }
    }

    private static func npxExecutableURL() -> URL? {
        var candidates = [
            "/opt/homebrew/bin/npx",
            "/usr/local/bin/npx",
            "/usr/bin/npx"
        ]
        candidates.append(
            contentsOf: (ProcessInfo.processInfo.environment["PATH"] ?? "")
                .split(separator: ":")
                .map { "\($0)/npx" }
        )

        var seen = Set<String>()
        guard let path = candidates.first(where: {
            seen.insert($0).inserted && FileManager.default.isExecutableFile(atPath: $0)
        }) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    private static func gatewayEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["HOST"] = "127.0.0.1"
        environment["NO_UPDATE_NOTIFIER"] = "true"
        return environment
    }

    private func attachOutputPipes(
        to process: Process,
        onOutput: @escaping (String) -> Void
    ) -> [Pipe] {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        for pipe in [outputPipe, errorPipe] {
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
                onOutput(text)
            }
        }
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        return [outputPipe, errorPipe]
    }

    private func clearGatewayOutputPipes() {
        clearOutputPipes(&gatewayOutputPipes)
    }

    private func clearAuthenticationOutputPipes() {
        clearOutputPipes(&authenticationOutputPipes)
    }

    private func clearOutputPipes(_ pipes: inout [Pipe]) {
        for pipe in pipes {
            pipe.fileHandleForReading.readabilityHandler = nil
        }
        pipes.removeAll()
    }

    private func clearCachedModelCatalog() {
        availableModels = []
        CopilotModelPreferences.saveCachedModels([])
    }

    private func isolateProcessGroup(for process: Process) {
        let pid = process.processIdentifier
        guard pid > 0 else { return }
        if setpgid(pid, pid) == 0 {
            isolatedProcessGroups.insert(pid)
        } else {
            NSLog("[Copilot] Could not isolate process group for PID %d", pid)
        }
    }

    private func terminate(_ process: Process) {
        let pid = process.processIdentifier
        let processGroupID: pid_t? = isolatedProcessGroups.remove(pid)
        let descendants = processGroupID == nil ? descendantProcessIDs(of: pid) : []

        if let processGroupID {
            _ = kill(-processGroupID, SIGTERM)
        } else {
            signal(descendants, with: SIGTERM)
            if process.isRunning {
                process.terminate()
            }
        }

        let deadline = Date().addingTimeInterval(ProcessTiming.gracefulTerminationTimeout)
        while isRunning(process, processGroupID: processGroupID, descendants: descendants), Date() < deadline {
            Thread.sleep(forTimeInterval: ProcessTiming.terminationPollInterval)
        }

        if isRunning(process, processGroupID: processGroupID, descendants: descendants) {
            if let processGroupID {
                _ = kill(-processGroupID, SIGKILL)
            } else {
                signal(descendants, with: SIGKILL)
                if process.isRunning {
                    _ = kill(pid, SIGKILL)
                }
            }
        }
    }

    private func isRunning(
        _ process: Process,
        processGroupID: pid_t?,
        descendants: [pid_t]
    ) -> Bool {
        if let processGroupID {
            return kill(-processGroupID, 0) == 0
        }
        return process.isRunning || descendants.contains { kill($0, 0) == 0 }
    }

    private func descendantProcessIDs(of pid: pid_t) -> [pid_t] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-P", String(pid)]
        let output = Pipe()
        task.standardOutput = output
        task.standardError = Pipe()

        guard (try? task.run()) != nil else { return [] }
        task.waitUntilExit()
        guard task.terminationStatus == 0,
              let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
            return []
        }

        let directChildren = text
            .split(whereSeparator: \.isNewline)
            .compactMap { pid_t(String($0)) }
        return directChildren + directChildren.flatMap(descendantProcessIDs)
    }

    private func signal(_ pids: [pid_t], with signal: Int32) {
        for pid in pids.reversed() {
            _ = kill(pid, signal)
        }
    }

    static func parseModels(from data: Data) -> [CopilotModelDescriptor]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelEntries = root["data"] as? [[String: Any]] else {
            return nil
        }

        let models = modelEntries.compactMap { entry -> CopilotModelDescriptor? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            if let policy = entry["policy"] as? [String: Any],
               (policy["state"] as? String)?.lowercased() == "disabled" {
                return nil
            }
            if (entry["model_picker_enabled"] as? Bool) == false {
                return nil
            }

            let endpoints = entry["supported_endpoints"] as? [String] ?? []
            guard endpoints.isEmpty || !Self.supportedGatewayEndpoints.isDisjoint(with: Set(endpoints)) else {
                return nil
            }

            let capabilities = entry["capabilities"] as? [String: Any] ?? [:]
            if (capabilities["type"] as? String)?.lowercased() == "embeddings" {
                return nil
            }
            let limits = capabilities["limits"] as? [String: Any] ?? [:]
            let supports = capabilities["supports"] as? [String: Any] ?? [:]
            let maxOutputTokens = (limits["max_output_tokens"] as? NSNumber)?.intValue ?? 128_000
            let contextWindow = (limits["max_context_window_tokens"] as? NSNumber)?.intValue
            let supportedReasoningEfforts = Set(
                (supports["reasoning_effort"] as? [String] ?? [])
                    .filter { Self.factoryReasoningEfforts.contains($0) }
            )
            let reasoningEfforts = Self.factoryReasoningEffortOrder.filter {
                supportedReasoningEfforts.contains($0)
            }

            return CopilotModelDescriptor(
                id: id,
                displayName: (entry["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? id,
                maxOutputTokens: maxOutputTokens > 0 ? maxOutputTokens : 128_000,
                maxContextLimit: contextWindow.flatMap { $0 > 0 ? $0 : nil },
                supportsVision: supports["vision"] as? Bool ?? false,
                reasoningEfforts: reasoningEfforts
            )
        }

        return models.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}

final class DeviceCodeCapture {
    private let lock = NSLock()
    private let onDeviceCode: (_ code: String, _ verificationURL: URL) -> Void
    private var buffer = ""
    private var delivered = false

    init(onDeviceCode: @escaping (_ code: String, _ verificationURL: URL) -> Void) {
        self.onDeviceCode = onDeviceCode
    }

    func append(_ text: String) {
        lock.lock()
        buffer += text
        if buffer.count > 8_192 {
            buffer = String(buffer.suffix(8_192))
        }
        let prompt = Self.parsePrompt(in: buffer)
        let shouldDeliver = prompt != nil && !delivered
        if shouldDeliver {
            delivered = true
        }
        lock.unlock()

        guard shouldDeliver, let prompt else { return }
        DispatchQueue.main.async {
            NSWorkspace.shared.open(prompt.url)
            self.onDeviceCode(prompt.code, prompt.url)
        }
    }

    static func parsePrompt(in text: String) -> (code: String, url: URL)? {
        let plainText = text.replacingOccurrences(
            of: "\u{001B}\\[[0-?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
        let codeMarker = "Please enter the code \""
        if let codeStart = plainText.range(of: codeMarker)?.upperBound,
           let codeEnd = plainText[codeStart...].firstIndex(of: "\"") {
            let code = String(plainText[codeStart..<codeEnd])
            let afterCode = plainText[codeEnd...]
            if let urlStart = afterCode.range(of: " in ")?.upperBound {
                let urlText = afterCode[urlStart...]
                    .prefix { !$0.isWhitespace }
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !code.isEmpty, let url = URL(string: String(urlText)) {
                    return (code, url)
                }
            }
        }

        let fullRange = NSRange(plainText.startIndex..., in: plainText)
        guard let urlExpression = try? NSRegularExpression(pattern: #"https?://[^\s<>"')\]]+"#),
              let urlMatch = urlExpression.firstMatch(in: plainText, range: fullRange),
              let urlRange = Range(urlMatch.range, in: plainText),
              let url = URL(
                string: String(plainText[urlRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".,;!"))
              ),
              let codeExpression = try? NSRegularExpression(
                pattern: #"(?:device\s*)?code\s*(?:is|:|=)?\s*["']?([A-Z0-9]{4,}(?:-[A-Z0-9]{2,})*)"#,
                options: .caseInsensitive
              ),
              let codeMatch = codeExpression.firstMatch(in: plainText, range: fullRange),
              let codeRange = Range(codeMatch.range(at: 1), in: plainText) else {
            return nil
        }
        return (String(plainText[codeRange]), url)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
