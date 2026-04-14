import Foundation
import Network

/**
 A lightweight HTTP proxy that injects reasoning settings for supported Claude 4.6 and Codex GPT models.

 Current behavior:
 - Requests whose `model` contains `opus-4-6` receive `thinking: {"type":"adaptive"}`
   plus `output_config.effort` from `AppPreferences.opus46ThinkingEffort`
 - Requests whose `model` contains `sonnet-4-6` receive `thinking: {"type":"adaptive"}`
   plus `output_config.effort` from `AppPreferences.sonnet46ThinkingEffort`
 - Requests whose `model` is exactly `gpt-5.3-codex` receive `reasoning: {"effort":"..."}`
   from `AppPreferences.gpt53CodexReasoningEffort`
 - Requests whose `model` is exactly `gpt-5.4` receive `reasoning: {"effort":"..."}`
   from `AppPreferences.gpt54ReasoningEffort`
 - Other models are forwarded unchanged

 The proxy edits the raw JSON string instead of re-serializing it so cache-sensitive key
 ordering is preserved.
 */
class ThinkingProxy {
    private var listener: NWListener?
    let proxyPort: UInt16 = 8317
    private let targetPort: UInt16 = 8318
    private let targetHost = "127.0.0.1"
    private(set) var isRunning = false
    private let stateQueue = DispatchQueue(label: "io.automaze.droidproxy.thinking-proxy-state")

    /// File-based debug logger (writes to /tmp/droidproxy-debug.log)
    private static let logFile: URL = URL(fileURLWithPath: "/tmp/droidproxy-debug.log")
    private static let logQueue = DispatchQueue(label: "io.automaze.droidproxy.file-log")
    static func fileLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        logQueue.async {
            if let data = line.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }

    private enum Config {
        static let anthropicVersion = "2023-06-01"
    }
    
    /**
     Starts the thinking proxy server on port 8317
     */
    func start() {
        guard !isRunning else {
            NSLog("[ThinkingProxy] Already running")
            return
        }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            guard let port = NWEndpoint.Port(rawValue: proxyPort) else {
                NSLog("[ThinkingProxy] Invalid port: %d", proxyPort)
                return
            }
            listener = try NWListener(using: parameters, on: port)
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    DispatchQueue.main.async {
                        self?.isRunning = true
                    }
                    NSLog("[ThinkingProxy] Listening on port \(self?.proxyPort ?? 0)")
                case .failed(let error):
                    NSLog("[ThinkingProxy] Failed: \(error)")
                    DispatchQueue.main.async {
                        self?.isRunning = false
                    }
                case .cancelled:
                    NSLog("[ThinkingProxy] Cancelled")
                    DispatchQueue.main.async {
                        self?.isRunning = false
                    }
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: .global(qos: .userInitiated))
            
        } catch {
            NSLog("[ThinkingProxy] Failed to start: \(error)")
        }
    }
    
    /**
     Stops the thinking proxy server
     */
    func stop() {
        stateQueue.sync {
            guard isRunning else { return }
            
            listener?.cancel()
            listener = nil
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
            }
            NSLog("[ThinkingProxy] Stopped")
        }
    }
    
    /**
     Handles an incoming connection from a client
     */
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(from: connection)
    }
    
    /**
     Receives the HTTP request from the client
     Accumulates data until full request is received (handles large payloads)
     */
    private func receiveRequest(from connection: NWConnection, accumulatedData: Data = Data()) {
        // Start the iterative receive loop
        receiveNextChunk(from: connection, accumulatedData: accumulatedData)
    }
    
    /**
     Receives request data iteratively (uses async scheduling instead of recursion to avoid stack buildup)
     */
    private func receiveNextChunk(from connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1048576) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("[ThinkingProxy] Receive error: \(error)")
                connection.cancel()
                return
            }
            
            guard let data = data, !data.isEmpty else {
                if isComplete {
                    connection.cancel()
                }
                return
            }
            
            var newAccumulatedData = accumulatedData
            newAccumulatedData.append(data)
            
            // Check if we have a complete HTTP request
            if let requestString = String(data: newAccumulatedData, encoding: .utf8),
               let headerEndRange = requestString.range(of: "\r\n\r\n") {
                
                // Extract Content-Length if present
                let headerEndIndex = requestString.distance(from: requestString.startIndex, to: headerEndRange.upperBound)
                let headerPart = String(requestString.prefix(headerEndIndex))
                
                if let contentLengthLine = headerPart.components(separatedBy: "\r\n").first(where: { $0.lowercased().starts(with: "content-length:") }) {
                    let contentLengthStr = contentLengthLine.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                    if let contentLength = Int(contentLengthStr) {
                        let bodyStartIndex = headerEndIndex
                        let currentBodyLength = newAccumulatedData.count - bodyStartIndex
                        
                        // If we haven't received the full body yet, schedule next iteration
                        if currentBodyLength < contentLength {
                            self.receiveNextChunk(from: connection, accumulatedData: newAccumulatedData)
                            return
                        }
                    }
                }
                
                // We have a complete request, process it
                self.processRequest(data: newAccumulatedData, connection: connection)
            } else if !isComplete {
                // Haven't found header end yet, schedule next iteration
                self.receiveNextChunk(from: connection, accumulatedData: newAccumulatedData)
            } else {
                // Complete but malformed, process what we have
                self.processRequest(data: newAccumulatedData, connection: connection)
            }
        }
    }
    
    /**
     Processes the HTTP request, modifies it if needed, and forwards to CLIProxyAPI
     */
    private func processRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendError(to: connection, statusCode: 400, message: "Invalid request")
            return
        }
        
        // Parse HTTP request
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendError(to: connection, statusCode: 400, message: "Invalid request line")
            return
        }
        
        // Extract method, path, and HTTP version
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 3 else {
            sendError(to: connection, statusCode: 400, message: "Invalid request format")
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        let httpVersion = parts[2]
        NSLog("[ThinkingProxy] Incoming request: \(method) \(path)")

        // Collect headers while preserving original casing
        var headers: [(String, String)] = []
        for line in lines.dropFirst() {
            if line.isEmpty { break }
            guard let separatorIndex = line.firstIndex(of: ":") else { continue }
            let name = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            let valueStart = line.index(after: separatorIndex)
            let value = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
            headers.append((name, value))
        }
        
        // Find the body start
        guard let bodyStartRange = requestString.range(of: "\r\n\r\n") else {
            NSLog("[ThinkingProxy] Error: Could not find body separator in request")
            sendError(to: connection, statusCode: 400, message: "Invalid request format - no body separator")
            return
        }
        
        let bodyStart = requestString.distance(from: requestString.startIndex, to: bodyStartRange.upperBound)
        let bodyString = String(requestString[requestString.index(requestString.startIndex, offsetBy: bodyStart)...])
        
        // Redirect Amp CLI login directly to ampcode.com to preserve auth state cookies
        if path.starts(with: "/auth/cli-login") || path.starts(with: "/api/auth/cli-login") {
            let loginPath = path.hasPrefix("/api/") ? String(path.dropFirst(4)) : path
            let redirectUrl = "https://ampcode.com" + loginPath
            NSLog("[ThinkingProxy] Redirecting Amp CLI login to: \(redirectUrl)")
            sendRedirect(to: connection, location: redirectUrl)
            return
        }

        // Rewrite Amp CLI paths
        var rewrittenPath = path
        if path.starts(with: "/provider/") {
            // Rewrite /provider/* to /api/provider/*
            rewrittenPath = "/api" + path
            NSLog("[ThinkingProxy] Rewriting Amp provider path: \(path) -> \(rewrittenPath)")
        }
        
        // Check if this is an Amp management request (anything not targeting provider or /v1)
        // Note: /provider/ paths are already rewritten to /api/provider/ above
        let isProviderPath = rewrittenPath.starts(with: "/api/provider/")
        let isCliProxyPath = rewrittenPath.starts(with: "/v1/") || rewrittenPath.starts(with: "/api/v1/")
        if !isProviderPath && !isCliProxyPath {
            let ampPath = rewrittenPath
            NSLog("[ThinkingProxy] Amp management request detected, forwarding to ampcode.com: \(ampPath)")
            forwardToAmp(method: method, path: ampPath, version: httpVersion, headers: headers, body: bodyString, originalConnection: connection)
            return
        }
        
        // Try to parse and modify JSON body for POST requests
        var modifiedBody = bodyString

        if method == "POST" && !bodyString.isEmpty {
            ThinkingProxy.fileLog("INCOMING REQUEST: \(method) \(rewrittenPath)")
            ThinkingProxy.fileLog("ORIGINAL BODY (first 500): \(String(bodyString.prefix(500)))")
            if let transformed = processThinkingParameter(jsonString: bodyString) {
                modifiedBody = transformed
                ThinkingProxy.fileLog("MODIFIED BODY (first 500): \(String(modifiedBody.prefix(500)))")
                ThinkingProxy.fileLog("THINKING INJECTED: true")
            }
            if let result = processOpenAIFastMode(jsonString: modifiedBody, path: rewrittenPath) {
                modifiedBody = result
            }
        }

        // Rewrite /v1/responses to /v1/chat/completions for Gemini models since
        // CLIProxyAPIPlus does not support Gemini via the Responses API endpoint.
        if isResponsesAPIPath(rewrittenPath) && isGeminiModel(bodyString) {
            let newPath = rewrittenPath.replacingOccurrences(of: "/responses", with: "/chat/completions")
            NSLog("[ThinkingProxy] Rewriting Gemini responses path: \(rewrittenPath) -> \(newPath)")
            ThinkingProxy.fileLog("REWRITE PATH: \(rewrittenPath) -> \(newPath) (Gemini model)")
            rewrittenPath = newPath
        }

        forwardRequest(method: method, path: rewrittenPath, version: httpVersion, headers: headers, body: modifiedBody, originalConnection: connection)
    }

    /**
     Processes the JSON body to add thinking or reasoning parameters for supported models.
     Uses surgical string operations to preserve original JSON structure and key ordering,
     which is critical for Anthropic's prompt caching (cache_control fields must be preserved).
     Returns tuple of (modifiedJSON, needsTransformation)
     */
    private func processThinkingParameter(jsonString: String) -> String? {
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let model = json["model"] as? String else {
            return nil
        }

        if let effort = codexReasoningEffort(for: model) {
            var result = jsonString
            result = injectJSONField(in: result, afterKey: "model", fieldName: "reasoning",
                                     fieldValue: "{\"effort\":\"\(effort)\"}")
            NSLog("[ThinkingProxy] Injected Codex reasoning for '\(model)' with effort '\(effort)'")
            ThinkingProxy.fileLog("INJECTED Codex reasoning: effort=\(effort) for model \(model)")
            return result
        }

        if let level = geminiThinkingLevel(for: model) {
            var result = jsonString
            result = injectJSONField(in: result, afterKey: "model", fieldName: "generationConfig",
                                     fieldValue: "{\"thinkingConfig\":{\"thinking_level\":\"\(level)\"}}")
            NSLog("[ThinkingProxy] Injected Gemini thinking for '\(model)' with level '\(level)'")
            ThinkingProxy.fileLog("INJECTED Gemini thinking: level=\(level) for model \(model)")
            return result
        }

        guard let effort = claudeAdaptiveThinkingEffort(for: model) else {
            return nil
        }

        var result = jsonString

        result = replaceOrInjectJSONField(in: result, afterKey: "model", fieldName: "stream",
                                          fieldValue: "true", existsInJSON: json["stream"] != nil)

        if AppPreferences.claudeMaxBudgetMode {
            let maxTokens = claudeMaxOutputTokens(for: model)
            let budgetTokens = maxTokens - 1

            result = replaceOrInjectJSONField(in: result, afterKey: "model", fieldName: "max_tokens",
                                              fieldValue: "\(maxTokens)", existsInJSON: json["max_tokens"] != nil)
            result = replaceOrInjectJSONField(in: result, afterKey: "max_tokens",
                                              fieldName: "thinking",
                                              fieldValue: "{\"type\":\"enabled\",\"budget_tokens\":\(budgetTokens)}",
                                              existsInJSON: json["thinking"] != nil)
            result = replaceOrInjectJSONField(in: result, afterKey: "thinking", fieldName: "output_config",
                                              fieldValue: "{\"effort\":\"max\"}",
                                              existsInJSON: json["output_config"] != nil)
            NSLog("[ThinkingProxy] Injected max budget thinking for '\(model)' with budget_tokens=\(budgetTokens), max_tokens=\(maxTokens)")
            ThinkingProxy.fileLog("INJECTED max budget thinking: budget_tokens=\(budgetTokens) max_tokens=\(maxTokens) for model \(model)")
        } else {
            result = replaceOrInjectJSONField(in: result, afterKey: "model", fieldName: "thinking",
                                              fieldValue: "{\"type\":\"adaptive\"}",
                                              existsInJSON: json["thinking"] != nil)
            result = replaceOrInjectJSONField(in: result, afterKey: "thinking", fieldName: "output_config",
                                              fieldValue: "{\"effort\":\"\(effort)\"}",
                                              existsInJSON: json["output_config"] != nil)
            NSLog("[ThinkingProxy] Injected adaptive thinking for '\(model)' with effort '\(effort)'")
            ThinkingProxy.fileLog("INJECTED adaptive thinking: effort=\(effort) for model \(model)")
        }

        return result
    }

    private func codexReasoningEffort(for model: String) -> String? {
        switch model {
        case "gpt-5.3-codex":
            return AppPreferences.gpt53CodexReasoningEffort
        case "gpt-5.4":
            return AppPreferences.gpt54ReasoningEffort
        default:
            return nil
        }
    }

    private func claudeMaxOutputTokens(for model: String) -> Int {
        if model.contains("opus-4-6") { return 128000 }
        if model.contains("sonnet-4-6") { return 64000 }
        return 64000
    }

    /// Replaces an existing JSON field's value or injects it if missing.
    private func replaceOrInjectJSONField(in json: String, afterKey: String, fieldName: String, fieldValue: String, existsInJSON: Bool) -> String {
        if existsInJSON {
            return replaceJSONFieldValue(in: json, fieldName: fieldName, newValue: fieldValue)
        }
        return injectJSONField(in: json, afterKey: afterKey, fieldName: fieldName, fieldValue: fieldValue)
    }

    /// Replaces the value of an existing JSON field using regex.
    private func replaceJSONFieldValue(in json: String, fieldName: String, newValue: String) -> String {
        let escapedKey = NSRegularExpression.escapedPattern(for: fieldName)
        let valuePattern = "(?:\"(?:[^\"\\\\]|\\\\.)*\"|\\-?\\d+(?:\\.\\d+)?|\\{[^}]*\\}|\\[[^\\]]*\\]|true|false|null)"
        let pattern = "(\"\(escapedKey)\"\\s*:\\s*)\(valuePattern)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)) else {
            NSLog("[ThinkingProxy] Warning: Could not find key '\(fieldName)' for value replacement")
            return json
        }
        var result = json
        let matchRange = Range(match.range, in: json)!
        let prefixRange = Range(match.range(at: 1), in: json)!
        let prefix = String(json[prefixRange])
        result.replaceSubrange(matchRange, with: "\(prefix)\(newValue)")
        return result
    }

    private func claudeAdaptiveThinkingEffort(for model: String) -> String? {
        guard model.starts(with: "claude-") || model.starts(with: "gemini-claude-") else {
            return nil
        }

        if model.contains("opus-4-6") {
            return AppPreferences.opus46ThinkingEffort
        }
        if model.contains("sonnet-4-6") {
            return AppPreferences.sonnet46ThinkingEffort
        }
        return nil
    }

    private func geminiThinkingLevel(for model: String) -> String? {
        switch model {
        case "gemini-3.1-pro-preview":
            return AppPreferences.gemini31ProThinkingLevel
        case "gemini-3-flash-preview":
            return AppPreferences.gemini3FlashThinkingLevel
        default:
            return nil
        }
    }

    private static let responsesAPIPaths: Set<String> = [
        "/v1/responses",
        "/api/v1/responses"
    ]

    private func isResponsesAPIPath(_ path: String) -> Bool {
        let normalizedPath = path.split(separator: "?").first.map(String.init) ?? path
        return Self.responsesAPIPaths.contains(normalizedPath)
    }

    private func isGeminiModel(_ bodyString: String) -> Bool {
        guard let jsonData = bodyString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let model = json["model"] as? String else {
            return false
        }
        return model.hasPrefix("gemini-")
    }

    private func rewriteModelValue(in json: String, from oldModel: String, to newModel: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: oldModel)
        let pattern = "(\"model\"\\s*:\\s*\")\(escaped)(\")"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)) else {
            NSLog("[ThinkingProxy] Warning: Could not find model value '\(oldModel)' for rewrite")
            return json
        }
        var result = json
        let matchRange = Range(match.range, in: json)!
        let replacement = "\"model\":\"\(newModel)\""
        result.replaceSubrange(matchRange, with: replacement)
        return result
    }

    // MARK: - Surgical JSON string helpers
    // These use regex to modify specific fields in-place, preserving the original JSON structure
    // and key ordering. This is critical because JSONSerialization.data() reorders keys
    // alphabetically, which breaks Anthropic's prompt cache matching.

    /// Injects a new JSON field after a given key's value in the JSON string.
    private func injectJSONField(in json: String, afterKey: String, fieldName: String, fieldValue: String) -> String {
        let escapedKey = NSRegularExpression.escapedPattern(for: afterKey)
        let valuePattern = "(?:\"(?:[^\"\\\\]|\\\\.)*\"|\\-?\\d+(?:\\.\\d+)?|\\{[^}]*\\}|\\[[^\\]]*\\]|true|false|null)"
        let pattern = "\"\(escapedKey)\"\\s*:\\s*\(valuePattern)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)) else {
            NSLog("[ThinkingProxy] Warning: Could not find key '\(afterKey)' for field injection")
            return json
        }
        let insertOffset = match.range.location + match.range.length
        let insertIndex = json.index(json.startIndex, offsetBy: insertOffset)
        var result = json
        result.insert(contentsOf: ",\"\(fieldName)\":\(fieldValue)", at: insertIndex)
        return result
    }

    private static let fastTierEligibleResponsePaths: Set<String> = [
        "/v1/responses",
        "/api/v1/responses"
    ]

    private func processOpenAIFastMode(jsonString: String, path: String) -> String? {
        let normalizedPath = path.split(separator: "?").first.map(String.init) ?? path
        guard Self.fastTierEligibleResponsePaths.contains(normalizedPath) else { return nil }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let model = json["model"] as? String else {
            return nil
        }

        switch model {
        case "gpt-5.4":
            guard AppPreferences.gpt54FastMode else { return nil }
        case "gpt-5.3-codex":
            guard AppPreferences.gpt53CodexFastMode else { return nil }
        default:
            return nil
        }

        guard json["service_tier"] == nil else { return nil }

        let result = injectJSONField(in: jsonString, afterKey: "model", fieldName: "service_tier",
                                     fieldValue: "\"priority\"")
        NSLog("[ThinkingProxy] Injected service_tier=priority for model '\(model)' on path \(path)")
        ThinkingProxy.fileLog("INJECTED service_tier=priority for model \(model)")
        return result
    }

    /**
     Forwards Amp API requests to ampcode.com, stripping the /api/ prefix
     */
    private func forwardToAmp(method: String, path: String, version: String, headers: [(String, String)], body: String, originalConnection: NWConnection) {
        // Create TLS parameters for HTTPS
        let tlsOptions = NWProtocolTLS.Options()
        let parameters = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
        
        // Create connection to ampcode.com:443
        let endpoint = NWEndpoint.hostPort(host: "ampcode.com", port: 443)
        let targetConnection = NWConnection(to: endpoint, using: parameters)
        
        targetConnection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Build the forwarded request
                var forwardedRequest = "\(method) \(path) \(version)\r\n"
                
                // Forward most headers, excluding some that need to be overridden
                let excludedHeaders: Set<String> = ["host", "content-length", "connection", "transfer-encoding"]
                for (name, value) in headers {
                    if !excludedHeaders.contains(name.lowercased()) {
                        forwardedRequest += "\(name): \(value)\r\n"
                    }
                }
                
                // Override Host header for ampcode.com
                forwardedRequest += "Host: ampcode.com\r\n"
                forwardedRequest += "Connection: close\r\n"
                
                let contentLength = body.utf8.count
                forwardedRequest += "Content-Length: \(contentLength)\r\n"
                forwardedRequest += "\r\n"
                forwardedRequest += body
                
                // Send to ampcode.com
                if let requestData = forwardedRequest.data(using: .utf8) {
                    targetConnection.send(content: requestData, completion: .contentProcessed({ error in
                        if let error = error {
                            NSLog("[ThinkingProxy] Send error to ampcode.com: \(error)")
                            targetConnection.cancel()
                            originalConnection.cancel()
                        } else {
                            // Receive response from ampcode.com and rewrite Location headers
                            self.receiveAmpResponse(from: targetConnection, originalConnection: originalConnection)
                        }
                    }))
                }
                
            case .failed(let error):
                NSLog("[ThinkingProxy] Connection to ampcode.com failed: \(error)")
                self.sendError(to: originalConnection, statusCode: 502, message: "Bad Gateway - Could not connect to ampcode.com")
                targetConnection.cancel()
                
            default:
                break
            }
        }
        
        targetConnection.start(queue: .global(qos: .userInitiated))
    }
    
    /**
     Receives response from ampcode.com and rewrites Location headers to add /api/ prefix
     */
    private func receiveAmpResponse(from targetConnection: NWConnection, originalConnection: NWConnection) {
        targetConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("[ThinkingProxy] Receive Amp response error: \(error)")
                targetConnection.cancel()
                originalConnection.cancel()
                return
            }
            
            if let data = data, !data.isEmpty {
                // Convert to string to rewrite headers
                if var responseString = String(data: data, encoding: .utf8) {
                    // Rewrite Location headers to prepend /api/
                    responseString = responseString.replacingOccurrences(
                        of: "\r\nlocation: /",
                        with: "\r\nlocation: /api/",
                        options: .caseInsensitive
                    )
                    responseString = responseString.replacingOccurrences(
                        of: "\r\nLocation: /",
                        with: "\r\nLocation: /api/"
                    )

                    // Rewrite absolute Location headers to keep browser on localhost proxy
                    responseString = responseString.replacingOccurrences(
                        of: "\r\nLocation: https://ampcode.com/",
                        with: "\r\nLocation: /api/",
                        options: .caseInsensitive
                    )
                    responseString = responseString.replacingOccurrences(
                        of: "\r\nLocation: http://ampcode.com/",
                        with: "\r\nLocation: /api/",
                        options: .caseInsensitive
                    )

                    // Rewrite cookie domain so browser accepts cookies from localhost
                    responseString = responseString.replacingOccurrences(
                        of: "Domain=.ampcode.com",
                        with: "Domain=localhost",
                        options: .caseInsensitive
                    )
                    responseString = responseString.replacingOccurrences(
                        of: "Domain=ampcode.com",
                        with: "Domain=localhost",
                        options: .caseInsensitive
                    )
                    
                    if let modifiedData = responseString.data(using: .utf8) {
                        originalConnection.send(content: modifiedData, completion: .contentProcessed({ sendError in
                            if let sendError = sendError {
                                NSLog("[ThinkingProxy] Send Amp response error: \(sendError)")
                            }
                            
                            if isComplete {
                                targetConnection.cancel()
                                originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                                    originalConnection.cancel()
                                }))
                            } else {
                                // Continue receiving more data
                                self.receiveAmpResponse(from: targetConnection, originalConnection: originalConnection)
                            }
                        }))
                    }
                } else {
                    // Not UTF-8, forward as-is
                    originalConnection.send(content: data, completion: .contentProcessed({ sendError in
                        if let sendError = sendError {
                            NSLog("[ThinkingProxy] Send Amp response error: \(sendError)")
                        }
                        
                        if isComplete {
                            targetConnection.cancel()
                            originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                                originalConnection.cancel()
                            }))
                        } else {
                            self.receiveAmpResponse(from: targetConnection, originalConnection: originalConnection)
                        }
                    }))
                }
            } else if isComplete {
                targetConnection.cancel()
                originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                    originalConnection.cancel()
                }))
            }
        }
    }

    /**
     Forwards the request to CLIProxyAPI on port 8318 (pass-through for non-thinking requests)
     */
    private func forwardRequest(method: String, path: String, version: String, headers: [(String, String)], body: String, originalConnection: NWConnection, retryWithApiPrefix: Bool = false) {
        // Create connection to CLIProxyAPI
        guard let port = NWEndpoint.Port(rawValue: targetPort) else {
            NSLog("[ThinkingProxy] Invalid target port: %d", targetPort)
            sendError(to: originalConnection, statusCode: 500, message: "Internal Server Error")
            return
        }
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(targetHost), port: port)
        let parameters = NWParameters.tcp
        let targetConnection = NWConnection(to: endpoint, using: parameters)
        
        targetConnection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Build the forwarded request
                var forwardedRequest = "\(method) \(path) \(version)\r\n"
                let excludedHeaders: Set<String> = ["content-length", "host", "transfer-encoding"]

                for (name, value) in headers {
                    let lowercasedName = name.lowercased()
                    if excludedHeaders.contains(lowercasedName) {
                        continue
                    }
                    forwardedRequest += "\(name): \(value)\r\n"
                }

                // Override Host header
                forwardedRequest += "Host: \(self.targetHost):\(self.targetPort)\r\n"
                // Always close connections - this proxy doesn't support keep-alive/pipelining
                forwardedRequest += "Connection: close\r\n"
                
                let contentLength = body.utf8.count
                forwardedRequest += "Content-Length: \(contentLength)\r\n"
                forwardedRequest += "\r\n"
                forwardedRequest += body
                
                // Send to CLIProxyAPI
                if let requestData = forwardedRequest.data(using: .utf8) {
                    targetConnection.send(content: requestData, completion: .contentProcessed({ error in
                        if let error = error {
                            NSLog("[ThinkingProxy] Send error: \(error)")
                            targetConnection.cancel()
                            originalConnection.cancel()
                        } else {
                            // Receive response from CLIProxyAPI (with 404 retry capability)
                            if retryWithApiPrefix {
                                self.receiveResponseWith404Retry(from: targetConnection, originalConnection: originalConnection, 
                                                                 method: method, path: path, version: version, 
                                                                 headers: headers, body: body)
                            } else {
                                self.receiveResponse(from: targetConnection, originalConnection: originalConnection)
                            }
                        }
                    }))
                }
                
            case .failed(let error):
                NSLog("[ThinkingProxy] Target connection failed: \(error)")
                self.sendError(to: originalConnection, statusCode: 502, message: "Bad Gateway")
                targetConnection.cancel()
                
            default:
                break
            }
        }
        
        targetConnection.start(queue: .global(qos: .userInitiated))
    }
    
    /**
     Receives response and retries with /api/ prefix on 404
     */
    private func receiveResponseWith404Retry(from targetConnection: NWConnection, originalConnection: NWConnection, 
                                             method: String, path: String, version: String, 
                                             headers: [(String, String)], body: String) {
        targetConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("[ThinkingProxy] Receive error: \(error)")
                targetConnection.cancel()
                originalConnection.cancel()
                return
            }
            
            if let data = data, !data.isEmpty {
                // Check if response is a 404
                if let responseString = String(data: data, encoding: .utf8) {
                    // Log first 200 chars to debug
                    let preview = String(responseString.prefix(200))
                    NSLog("[ThinkingProxy] Response preview for \(path): \(preview)")
                    
                    // Check for 404 in status line OR in body
                    let is404 = responseString.contains("HTTP/1.1 404") || 
                               responseString.contains("HTTP/1.0 404") ||
                               responseString.contains("404 page not found")
                    
                    if is404 {
                        // Check if path doesn't already start with /api/
                        if !path.starts(with: "/api/") && !path.starts(with: "/v1/") {
                            NSLog("[ThinkingProxy] Got 404 for \(path), retrying with /api prefix")
                            targetConnection.cancel()
                            
                            // Retry with /api/ prefix
                            let newPath = "/api" + path
                            self.forwardRequest(method: method, path: newPath, version: version, headers: headers, 
                                              body: body, originalConnection: originalConnection, retryWithApiPrefix: false)
                            return
                        }
                    }
                }
                
                // Not a 404 or already has /api/, forward response as-is
                originalConnection.send(content: data, completion: .contentProcessed({ sendError in
                    if let sendError = sendError {
                        NSLog("[ThinkingProxy] Send error: \(sendError)")
                    }
                    
                    if isComplete {
                        targetConnection.cancel()
                        originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                            originalConnection.cancel()
                        }))
                    } else {
                        // Continue streaming
                        self.streamNextChunk(from: targetConnection, to: originalConnection)
                    }
                }))
            } else if isComplete {
                targetConnection.cancel()
                originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                    originalConnection.cancel()
                }))
            }
        }
    }
    
    /**
     Receives response from CLIProxyAPI
     Starts the streaming loop for response data
     */
    private func receiveResponse(from targetConnection: NWConnection, originalConnection: NWConnection) {
        // Start the streaming loop
        streamNextChunk(from: targetConnection, to: originalConnection)
    }
    
    /**
     Streams response chunks iteratively (uses async scheduling instead of recursion to avoid stack buildup)
     */
    private func streamNextChunk(from targetConnection: NWConnection, to originalConnection: NWConnection) {
        targetConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("[ThinkingProxy] Receive response error: \(error)")
                targetConnection.cancel()
                originalConnection.cancel()
                return
            }
            
            if let data = data, !data.isEmpty {
                // Forward response chunk to original client
                originalConnection.send(content: data, completion: .contentProcessed({ sendError in
                    if let sendError = sendError {
                        NSLog("[ThinkingProxy] Send response error: \(sendError)")
                    }
                    
                    if isComplete {
                        targetConnection.cancel()
                        // Always close client connection - no keep-alive/pipelining support
                        originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                            originalConnection.cancel()
                        }))
                    } else {
                        // Schedule next iteration of the streaming loop
                        self.streamNextChunk(from: targetConnection, to: originalConnection)
                    }
                }))
            } else if isComplete {
                targetConnection.cancel()
                // Always close client connection - no keep-alive/pipelining support
                originalConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ _ in
                    originalConnection.cancel()
                }))
            }
        }
    }
    
    /**
     Sends an error response to the client
     */
    private func sendError(to connection: NWConnection, statusCode: Int, message: String) {
        // Build response with proper CRLF line endings and correct byte count
        guard let bodyData = message.data(using: .utf8) else {
            connection.cancel()
            return
        }
        
        let headers = "HTTP/1.1 \(statusCode) \(message)\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: \(bodyData.count)\r\n" +
                     "Connection: close\r\n" +
                     "\r\n"
        
        guard let headerData = headers.data(using: .utf8) else {
            connection.cancel()
            return
        }
        
        var responseData = Data()
        responseData.append(headerData)
        responseData.append(bodyData)
        
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendRedirect(to connection: NWConnection, location: String) {
        let headers = "HTTP/1.1 302 Found\r\n" +
                     "Location: \(location)\r\n" +
                     "Content-Length: 0\r\n" +
                     "Connection: close\r\n" +
                     "\r\n"

        guard let headerData = headers.data(using: .utf8) else {
            connection.cancel()
            return
        }

        connection.send(content: headerData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
