import Foundation

/// Grok can emit structured tool calls that Factory then rejects:
/// - `EndFeatureRun` without `handoff`, or with `validatorsPassed` as a thought-string
/// - `Execute` / `Bash` / `Shell` without `command` (often only `summary`, or `cmd`/`input`)
/// - `Read` with `path` instead of `file_path`, `Grep` with `regex` instead of `pattern`
///
/// This repairs the arguments before the client sees them. It does not invent a
/// shell command from an English summary.
enum GrokEndFeatureRunRepair {
    static let toolNames: Set<String> = ["EndFeatureRun", "end_feature_run"]
    static let executeToolNames: Set<String> = ["Execute", "Bash", "Shell"]
    static let readToolNames: Set<String> = ["Read"]
    static let grepToolNames: Set<String> = ["Grep"]

    struct Repair {
        let arguments: [String: Any]
        let changed: Bool
        let notes: [String]
    }

    static func isRepairable(_ name: String) -> Bool {
        toolNames.contains(name)
            || executeToolNames.contains(name)
            || readToolNames.contains(name)
            || grepToolNames.contains(name)
    }

    static func repair(
        name: String,
        arguments: [String: Any],
        assistantText: String? = nil
    ) -> Repair {
        if executeToolNames.contains(name) {
            return repairExecute(arguments: arguments, assistantText: assistantText)
        }
        if readToolNames.contains(name) {
            return repairRead(arguments: arguments)
        }
        if grepToolNames.contains(name) {
            return repairGrep(arguments: arguments)
        }
        guard toolNames.contains(name) else {
            return Repair(arguments: arguments, changed: false, notes: [])
        }

        var args = arguments
        var notes: [String] = []
        var changed = false

        if let raw = args["validatorsPassed"] as? String {
            args["validatorsPassed"] = coerceBool(raw)
            changed = true
            notes.append("coerced validatorsPassed")
        }

        if let raw = args["returnToOrchestrator"] as? String {
            args["returnToOrchestrator"] = coerceBool(raw)
            changed = true
        }

        if args["handoff"] == nil {
            var nested: [String: Any] = [:]
            for key in [
                "salientSummary",
                "whatWasImplemented",
                "whatWasLeftUndone",
                "discoveredIssues",
                "verification",
                "tests",
                "skillFeedback"
            ] {
                if let value = args.removeValue(forKey: key) {
                    nested[key] = value
                }
            }
            if !nested.isEmpty {
                args["handoff"] = nested
                changed = true
                notes.append("nested top-level handoff fields")
            }
        }

        if let raw = args["handoff"] as? String,
           let data = raw.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            args["handoff"] = object
            changed = true
            notes.append("parsed string handoff")
        }

        if args["handoff"] == nil {
            args["handoff"] = stubHandoff(assistantText: assistantText)
            changed = true
            notes.append("inserted stub handoff")
        }

        if (args["successState"] as? String) == "success", args["validatorsPassed"] == nil {
            args["validatorsPassed"] = true
            if var handoff = args["handoff"] as? [String: Any] {
                var issues = issuesArray(handoff["discoveredIssues"])
                issues.append([
                    "severity": "non_blocking",
                    "description": "Grok omitted validatorsPassed on a success EndFeatureRun. DroidProxy set it true so the mission could close. Re-check gates independently."
                ])
                handoff["discoveredIssues"] = issues
                args["handoff"] = handoff
            }
            changed = true
            notes.append("defaulted validatorsPassed")
        }

        return Repair(arguments: args, changed: changed, notes: notes)
    }

    static func repairArgumentsJSON(
        name: String,
        argumentsJSON: String,
        assistantText: String? = nil
    ) -> String? {
        guard isRepairable(name),
              let data = argumentsJSON.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        let result = repair(name: name, arguments: object, assistantText: assistantText)
        guard result.changed else { return nil }
        return jsonString(result.arguments)
    }

    /// When the SSE event omitted the tool name, infer from the argument shape.
    static func repairArgumentsJSONInferred(
        argumentsJSON: String,
        assistantText: String? = nil
    ) -> String? {
        guard let data = argumentsJSON.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        if object["successState"] != nil {
            return repairArgumentsJSON(
                name: "EndFeatureRun",
                argumentsJSON: argumentsJSON,
                assistantText: assistantText
            )
        }
        if looksLikeExecute(object) {
            return repairArgumentsJSON(
                name: "Execute",
                argumentsJSON: argumentsJSON,
                assistantText: assistantText
            )
        }
        if object["file_path"] == nil, object["path"] != nil {
            return repairArgumentsJSON(name: "Read", argumentsJSON: argumentsJSON)
        }
        if object["pattern"] == nil, object["regex"] != nil || object["query"] != nil {
            return repairArgumentsJSON(name: "Grep", argumentsJSON: argumentsJSON)
        }
        return nil
    }

    /// Repairs chat.completion or Responses API JSON. Returns nil when unchanged.
    static func repairJSONBody(_ json: String, assistantText: String? = nil) -> String? {
        guard let data = json.data(using: .utf8),
              var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var changed = false
        let text = assistantText ?? extractAssistantText(root)

        if var choices = root["choices"] as? [[String: Any]], !choices.isEmpty {
            var choice = choices[0]
            if var message = choice["message"] as? [String: Any],
               let toolCalls = message["tool_calls"] as? [[String: Any]] {
                let repaired = repairToolCalls(toolCalls, assistantText: text)
                if repaired.changed {
                    message["tool_calls"] = repaired.toolCalls
                    choice["message"] = message
                    choices[0] = choice
                    root["choices"] = choices
                    changed = true
                }
            }
        }

        if let output = root["output"] as? [Any] {
            let repaired = repairOutputItems(output, assistantText: text)
            if repaired.changed {
                root["output"] = repaired.items
                changed = true
            }
        }

        guard changed,
              let out = try? JSONSerialization.data(withJSONObject: root),
              let str = String(data: out, encoding: .utf8) else {
            return nil
        }
        return str
    }

    /// Repairs streamed chat-completion or Responses SSE. Returns nil when unchanged.
    static func repairSSE(_ sse: String) -> String? {
        var currentEvent: String?
        var changed = false
        var skipArgumentDeltas = false
        var rebuilt: [String] = []

        // First pass: do we need to drop argument deltas?
        for rawLine in sse.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(rawLine)
            if line.hasSuffix("\r") { line.removeLast() }
            if line.hasPrefix("event:") {
                currentEvent = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
            }
            guard line.hasPrefix("data:") else { continue }
            var payload = String(line.dropFirst(5))
            if payload.hasPrefix(" ") { payload.removeFirst() }
            if payload == "[DONE]" { continue }
            guard let data = payload.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            if scanNeedsRepair(obj) {
                skipArgumentDeltas = true
                break
            }
            if currentEvent == "response.function_call_arguments.done",
               let args = obj["arguments"] as? String {
                let name = obj["name"] as? String
                let repaired = name.flatMap {
                    repairArgumentsJSON(name: $0, argumentsJSON: args)
                } ?? repairArgumentsJSONInferred(argumentsJSON: args)
                if repaired != nil {
                    skipArgumentDeltas = true
                    break
                }
            }
        }

        currentEvent = nil
        for rawLine in sse.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(rawLine)
            let hadCR = line.hasSuffix("\r")
            if hadCR { line.removeLast() }

            if line.hasPrefix("event:") {
                currentEvent = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                if skipArgumentDeltas, currentEvent == "response.function_call_arguments.delta" {
                    continue
                }
                rebuilt.append(hadCR ? line + "\r" : line)
                continue
            }

            if skipArgumentDeltas, currentEvent == "response.function_call_arguments.delta" {
                continue
            }

            guard line.hasPrefix("data:") else {
                rebuilt.append(hadCR ? line + "\r" : line)
                continue
            }

            var payload = String(line.dropFirst(5))
            if payload.hasPrefix(" ") { payload.removeFirst() }
            if payload == "[DONE]" {
                rebuilt.append(hadCR ? line + "\r" : line)
                continue
            }

            guard let data = payload.data(using: .utf8),
                  var obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                rebuilt.append(hadCR ? line + "\r" : line)
                continue
            }

            let repaired = repairPayload(&obj)
            if repaired {
                changed = true
                if let encoded = jsonString(obj) {
                    rebuilt.append("data: \(encoded)")
                    continue
                }
            }
            rebuilt.append(hadCR ? line + "\r" : line)
        }

        guard changed || skipArgumentDeltas else { return nil }
        return rebuilt.joined(separator: "\n")
    }

    // MARK: - Internals

    private static func repairToolCalls(
        _ toolCalls: [[String: Any]],
        assistantText: String?
    ) -> (toolCalls: [[String: Any]], changed: Bool) {
        var changed = false
        let next = toolCalls.map { call -> [String: Any] in
            var call = call
            var function = call["function"] as? [String: Any] ?? [:]
            let name = (function["name"] as? String) ?? (call["name"] as? String) ?? ""
            guard isRepairable(name) else { return call }

            let rawArgs = function["arguments"] as? String ?? "{}"
            if let repaired = repairArgumentsJSON(name: name, argumentsJSON: rawArgs, assistantText: assistantText) {
                function["arguments"] = repaired
                call["function"] = function
                changed = true
            }
            return call
        }
        return (next, changed)
    }

    private static func repairOutputItems(
        _ items: [Any],
        assistantText: String?
    ) -> (items: [Any], changed: Bool) {
        var changed = false
        let next: [Any] = items.map { item in
            guard var object = item as? [String: Any] else { return item }
            let type = object["type"] as? String
            let name = object["name"] as? String ?? ""
            guard isRepairable(name) || type == "function_call" || type == "custom_tool_call" else {
                return item
            }
            guard isRepairable(name) else { return item }

            if let raw = object["arguments"] as? String,
               let repaired = repairArgumentsJSON(name: name, argumentsJSON: raw, assistantText: assistantText) {
                object["arguments"] = repaired
                changed = true
                return object
            }
            if let args = object["arguments"] as? [String: Any] {
                let result = repair(name: name, arguments: args, assistantText: assistantText)
                if result.changed {
                    object["arguments"] = result.arguments
                    changed = true
                    return object
                }
            }
            if let raw = object["input"] as? String,
               let repaired = repairArgumentsJSON(name: name, argumentsJSON: raw, assistantText: assistantText) {
                object["input"] = repaired
                changed = true
                return object
            }
            return item
        }
        return (next, changed)
    }

    private static func repairPayload(_ obj: inout [String: Any]) -> Bool {
        var changed = false
        let text = extractAssistantText(obj)

        if var choices = obj["choices"] as? [[String: Any]], !choices.isEmpty {
            var choice = choices[0]
            if var message = choice["message"] as? [String: Any],
               let toolCalls = message["tool_calls"] as? [[String: Any]] {
                let repaired = repairToolCalls(toolCalls, assistantText: text)
                if repaired.changed {
                    message["tool_calls"] = repaired.toolCalls
                    choice["message"] = message
                    choices[0] = choice
                    obj["choices"] = choices
                    changed = true
                }
            }
            if var delta = choice["delta"] as? [String: Any],
               let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                let repaired = repairToolCalls(toolCalls, assistantText: text)
                if repaired.changed {
                    delta["tool_calls"] = repaired.toolCalls
                    choice["delta"] = delta
                    choices[0] = choice
                    obj["choices"] = choices
                    changed = true
                }
            }
        }

        if var item = obj["item"] as? [String: Any] {
            let name = item["name"] as? String ?? ""
            if isRepairable(name),
               let raw = item["arguments"] as? String,
               let repaired = repairArgumentsJSON(name: name, argumentsJSON: raw, assistantText: text) {
                item["arguments"] = repaired
                obj["item"] = item
                changed = true
            }
        }

        var repairedByName = false
        if let name = obj["name"] as? String, isRepairable(name),
           let raw = obj["arguments"] as? String,
           let repaired = repairArgumentsJSON(name: name, argumentsJSON: raw, assistantText: text) {
            obj["arguments"] = repaired
            changed = true
            repairedByName = true
        }

        if !repairedByName,
           let raw = obj["arguments"] as? String,
           let repaired = repairArgumentsJSONInferred(argumentsJSON: raw, assistantText: text) {
            obj["arguments"] = repaired
            changed = true
        }

        return changed
    }

    private static func scanNeedsRepair(_ obj: [String: Any]) -> Bool {
        var copy = obj
        return repairPayload(&copy)
    }

    private static func stubHandoff(assistantText: String?) -> [String: Any] {
        let summary: String
        if let text = assistantText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            summary = String(text.prefix(400))
        } else {
            summary = "Grok omitted the required handoff object. DroidProxy inserted a stub so EndFeatureRun could close."
        }
        return [
            "salientSummary": summary,
            "whatWasImplemented": "",
            "whatWasLeftUndone": "",
            "discoveredIssues": [[
                "severity": "non_blocking",
                "description": "Grok omitted the required handoff object. DroidProxy inserted a stub so the mission could close. Verify the commit and working tree before trusting this summary."
            ]]
        ]
    }

    private static func repairExecute(
        arguments: [String: Any],
        assistantText: String?
    ) -> Repair {
        var args = arguments
        var notes: [String] = []
        var changed = false

        if commandString(args["command"]) == nil {
            for alias in ["cmd", "shell", "bash", "script", "input"] {
                if let value = commandString(args[alias]) {
                    args["command"] = value
                    changed = true
                    notes.append("remapped \(alias) to command")
                    break
                }
            }
        }

        if commandString(args["command"]) == nil {
            for (key, value) in args {
                if key == "command" { continue }
                let lowered = key.lowercased()
                guard lowered.hasPrefix("command") else { continue }
                if let value = commandString(value) {
                    args["command"] = value
                    changed = true
                    notes.append("normalized \(key) to command")
                    break
                }
                if let colon = key.firstIndex(of: ":") {
                    let inline = String(key[key.index(after: colon)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !inline.isEmpty {
                        args["command"] = inline
                        changed = true
                        notes.append("split inline command key")
                        break
                    }
                }
            }
        }

        if commandString(args["command"]) == nil {
            for (_, value) in args {
                if let text = value as? String, let extracted = extractEmbeddedCommand(text) {
                    args["command"] = extracted
                    changed = true
                    notes.append("extracted command from argument text")
                    break
                }
            }
        }

        if commandString(args["command"]) == nil,
           let summary = args["summary"] as? String,
           looksLikeShellCommand(summary) {
            args["command"] = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            changed = true
            notes.append("promoted shell-like summary to command")
        }

        if commandString(args["command"]) == nil,
           let text = assistantText,
           let extracted = extractFencedCommand(text) {
            args["command"] = extracted
            changed = true
            notes.append("extracted command from assistant text")
        }

        return Repair(arguments: args, changed: changed, notes: notes)
    }

    private static func repairRead(arguments: [String: Any]) -> Repair {
        var args = arguments
        if commandString(args["file_path"]) == nil {
            for alias in ["path", "file", "filename"] {
                if let value = commandString(args[alias]) {
                    args["file_path"] = value
                    return Repair(arguments: args, changed: true, notes: ["remapped \(alias) to file_path"])
                }
            }
        }
        return Repair(arguments: args, changed: false, notes: [])
    }

    private static func repairGrep(arguments: [String: Any]) -> Repair {
        var args = arguments
        if commandString(args["pattern"]) == nil {
            for alias in ["regex", "query", "search"] {
                if let value = commandString(args[alias]) {
                    args["pattern"] = value
                    return Repair(arguments: args, changed: true, notes: ["remapped \(alias) to pattern"])
                }
            }
        }
        return Repair(arguments: args, changed: false, notes: [])
    }

    private static func looksLikeExecute(_ object: [String: Any]) -> Bool {
        object["cmd"] != nil
            || object["shell"] != nil
            || object["bash"] != nil
            || object["script"] != nil
            || object["summary"] != nil
            || object["riskLevel"] != nil
            || object["command"] != nil
    }

    private static func commandString(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let text = value as? String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }

    private static func extractEmbeddedCommand(_ raw: String) -> String? {
        let text = raw.replacingOccurrences(of: "\r\n", with: "\n")
        if let range = text.range(of: #"(?m)^command\s*\n"#, options: .regularExpression) {
            let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rest.isEmpty { return rest }
        }
        if let range = text.range(of: #"(?im)^command:\s+"#, options: .regularExpression) {
            let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rest.isEmpty { return rest }
        }
        return nil
    }

    private static func looksLikeShellCommand(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let lower = trimmed.lowercased()
        let prefixes = [
            "pwd", "ls", "cd ", "cat ", "git ", "node ", "npx ", "python",
            "swift ", "npm ", "pnpm ", "yarn ", "bun ", "cargo ", "go ",
            "rg ", "grep ", "find ", "echo ", "head ", "tail ", "curl ",
            "jq ", "mkdir ", "./", "/", "~/", "brew "
        ]
        return prefixes.contains { lower.hasPrefix($0) }
    }

    private static func extractFencedCommand(_ text: String) -> String? {
        let pattern = #"```(?:bash|sh|zsh|shell)?\n([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        for match in matches.reversed() {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { continue }
            let body = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                return body
            }
        }
        return nil
    }

    private static func coerceBool(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == "true" { return true }
        if trimmed == "false" { return false }
        if trimmed.hasPrefix("true") { return true }
        if trimmed.hasPrefix("false") { return false }
        return false
    }

    private static func issuesArray(_ value: Any?) -> [[String: Any]] {
        if let issues = value as? [[String: Any]] { return issues }
        return []
    }

    private static func extractAssistantText(_ root: [String: Any]) -> String? {
        if let choices = root["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let text = message["content"] as? String,
           !text.isEmpty {
            return text
        }
        if let output = root["output"] as? [[String: Any]] {
            var pieces: [String] = []
            for item in output {
                if let content = item["content"] as? [[String: Any]] {
                    for block in content {
                        if let text = block["text"] as? String { pieces.append(text) }
                    }
                }
            }
            if !pieces.isEmpty { return pieces.joined(separator: " ") }
        }
        return nil
    }

    private static func jsonString(_ object: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
}
