import Foundation

/// Sanitizes Factory/Droid `/v1/responses` bodies before forwarding to api.x.ai.
///
/// xAI rejects:
/// - OpenAI-style `"type":"custom"` tool definitions (HTTP 422)
/// - `"type":"custom_tool_call"` / `"custom_tool_call_output"` items in `input`
///   (HTTP 422: `data did not match any variant of untagged enum ModelInput`)
/// - `tool_choice` / `parallel_tool_calls` when `tools` is empty or absent (HTTP 400)
///
/// Client tools are remapped to `"function"`; unsupported tool types are dropped.
/// Nested chat-completions function wrappers are flattened. Custom tool-call
/// history items become `function_call` / `function_call_output` with object
/// `arguments` (xAI rejects non-object argument values). Execute/Bash/Shell
/// schemas get a required `command` property when Factory omitted it.
enum GrokRequestSanitizer {
    /// Tool `type` values accepted by api.x.ai Responses (from the 422 allowlist).
    static let allowedToolTypes: Set<String> = [
        "function",
        "web_search",
        "x_search",
        "collections_search",
        "file_search",
        "code_search",
        "code_execution",
        "code_interpreter",
        "mcp",
        "shell"
    ]

    private static let emptyParameters: [String: Any] = [
        "type": "object",
        "properties": [:] as [String: Any]
    ]

    static let executeToolNames: Set<String> = ["Execute", "Bash", "Shell"]

    /// Returns a body safe for api.x.ai, or the original string when unchanged / unparseable.
    /// Re-serialization may reorder JSON keys (acceptable for api.x.ai; not used on Anthropic paths).
    static func sanitize(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return json
        }

        var changed = false

        if let tools = root["tools"] as? [Any] {
            let (sanitizedTools, toolsChanged) = sanitizeToolsArray(tools)
            if toolsChanged {
                changed = true
                if sanitizedTools.isEmpty {
                    root.removeValue(forKey: "tools")
                } else {
                    root["tools"] = sanitizedTools
                }
            }
        }

        if let choice = root["tool_choice"] as? [String: Any],
           let sanitizedChoice = sanitizeToolChoice(choice) {
            root["tool_choice"] = sanitizedChoice
            changed = true
        }

        if let input = root["input"] as? [Any] {
            let (sanitizedInput, inputChanged) = sanitizeInputArray(input)
            if inputChanged {
                changed = true
                root["input"] = sanitizedInput
            }
        }

        // After tool filtering, drop orphaned tool_choice / parallel_tool_calls.
        // xAI: "A tool_choice was set on the request but no tools were specified."
        if dropOrphanedToolControls(&root) {
            changed = true
        }

        guard changed,
              let out = try? JSONSerialization.data(withJSONObject: root),
              let str = String(data: out, encoding: .utf8) else {
            return json
        }
        return str
    }

    static func sanitizeToolsArray(_ tools: [Any]) -> (tools: [[String: Any]], changed: Bool) {
        var sanitized: [[String: Any]] = []
        var changed = false

        for entry in tools {
            guard let tool = entry as? [String: Any] else {
                changed = true
                continue
            }
            guard let next = sanitizeTool(tool) else {
                changed = true
                continue
            }
            sanitized.append(next)
            if !nsEqual(next, tool) {
                changed = true
            }
        }

        return (sanitized, changed)
    }

    /// Remap / drop a single tools[] entry. Returns nil to drop.
    static func sanitizeTool(_ tool: [String: Any]) -> [String: Any]? {
        let type = tool["type"] as? String

        // Chat-completions wrapper: {"type":"function","function":{name,description,parameters}}
        if (type == "function" || type == "custom"),
           let nested = tool["function"] as? [String: Any] {
            return flattenFunctionTool(nested)
        }

        if type == "custom" || type == "function" {
            return flattenFunctionTool(tool)
        }

        guard let resolvedType = type, allowedToolTypes.contains(resolvedType) else {
            return nil
        }

        // Built-ins: pass through (web_search, x_search, …).
        return tool
    }

    /// Converts `custom_tool_call` / `custom_tool_call_output` history items that
    /// Factory/Codex emit but xAI's ModelInput enum does not accept.
    static func sanitizeInputArray(_ input: [Any]) -> (input: [Any], changed: Bool) {
        var sanitized: [Any] = []
        var changed = false

        for entry in input {
            guard var item = entry as? [String: Any] else {
                sanitized.append(entry)
                continue
            }

            let type = item["type"] as? String
            switch type {
            case "custom_tool_call":
                item["type"] = "function_call"
                if item["input"] != nil {
                    item["arguments"] = customToolCallArgumentsJSON(
                        item["input"],
                        toolName: item["name"] as? String
                    )
                    item.removeValue(forKey: "input")
                } else if item["arguments"] == nil {
                    item["arguments"] = "{}"
                } else if let args = item["arguments"] as? [String: Any],
                          let encoded = jsonString(args) {
                    // xAI expects arguments as a JSON-object *string*.
                    item["arguments"] = encoded
                } else if !(item["arguments"] is String) {
                    item["arguments"] = customToolCallArgumentsJSON(item["arguments"])
                }
                changed = true
                sanitized.append(item)

            case "custom_tool_call_output":
                item["type"] = "function_call_output"
                changed = true
                sanitized.append(item)

            default:
                sanitized.append(entry)
            }
        }

        return (sanitized, changed)
    }

    private static func flattenFunctionTool(_ source: [String: Any]) -> [String: Any]? {
        guard let name = source["name"] as? String, !name.isEmpty else {
            return nil
        }

        var flat: [String: Any] = [
            "type": "function",
            "name": name
        ]

        if let description = source["description"] as? String {
            flat["description"] = description
        }

        if let parameters = source["parameters"] as? [String: Any] {
            flat["parameters"] = parameters
        } else if let parameters = source["input_schema"] as? [String: Any] {
            // Anthropic-shaped schema some clients attach to custom tools.
            flat["parameters"] = parameters
        } else {
            flat["parameters"] = emptyParameters
        }

        if let strict = source["strict"] as? Bool {
            flat["strict"] = strict
        }

        ensureKnownToolParameters(&flat)
        return flat
    }

    /// Grok often calls Execute with only `summary` when `command` is missing
    /// from the schema (or buried). Pin the required field on the way out.
    @discardableResult
    static func ensureKnownToolParameters(_ tool: inout [String: Any]) -> Bool {
        guard let name = tool["name"] as? String else { return false }
        var params = tool["parameters"] as? [String: Any] ?? ["type": "object"]
        var props = params["properties"] as? [String: Any] ?? [:]
        var required = params["required"] as? [String] ?? []
        var changed = false

        func ensureProperty(_ key: String, description: String) {
            if props[key] == nil {
                props[key] = [
                    "type": "string",
                    "description": description
                ]
                changed = true
            }
            if !required.contains(key) {
                required.insert(key, at: 0)
                changed = true
            }
        }

        if executeToolNames.contains(name) {
            let wasMissing = props["command"] == nil || !required.contains("command")
            ensureProperty(
                "command",
                description: "The exact shell command to run. Required. Never omit this field or replace it with summary."
            )
            if wasMissing {
                let suffix = " The command field is required and must be the exact shell string; summary is optional metadata only."
                if let description = tool["description"] as? String,
                   !description.contains("command field is required") {
                    tool["description"] = description + suffix
                    changed = true
                } else if tool["description"] == nil {
                    tool["description"] = "Run a shell command." + suffix
                    changed = true
                }
            }
        }

        guard changed else { return false }
        params["type"] = "object"
        params["properties"] = props
        params["required"] = required
        tool["parameters"] = params
        return true
    }

    /// Returns a rewritten tool_choice when `custom` must become `function`; nil if unchanged.
    private static func sanitizeToolChoice(_ choice: [String: Any]) -> [String: Any]? {
        guard let type = choice["type"] as? String else {
            return nil
        }

        if type == "custom" {
            var rewritten = choice
            rewritten["type"] = "function"
            return rewritten
        }

        if type == "function",
           choice["name"] == nil,
           let nested = choice["function"] as? [String: Any],
           let name = nested["name"] as? String {
            return ["type": "function", "name": name]
        }

        return nil
    }

    /// Drop empty `tools` and orphaned `tool_choice` / `parallel_tool_calls`.
    @discardableResult
    private static func dropOrphanedToolControls(_ root: inout [String: Any]) -> Bool {
        var changed = false

        let hasTools: Bool
        if let tools = root["tools"] as? [Any] {
            hasTools = !tools.isEmpty
            if !hasTools {
                root.removeValue(forKey: "tools")
                changed = true
            }
        } else {
            hasTools = false
        }

        guard !hasTools else { return changed }

        if root.removeValue(forKey: "tool_choice") != nil {
            changed = true
        }
        if root.removeValue(forKey: "parallel_tool_calls") != nil {
            changed = true
        }
        return changed
    }

    /// Wrap freeform custom-tool `input` into a JSON-object arguments string.
    private static func customToolCallArgumentsJSON(_ value: Any?, toolName: String? = nil) -> String {
        guard let value else { return "{}" }

        if let text = value as? String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("{"),
               let data = trimmed.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) is [String: Any] {
                return trimmed
            }
            let key = executeToolNames.contains(toolName ?? "") ? "command" : "input"
            if let encoded = jsonString([key: text]) {
                return encoded
            }
            return "{}"
        }

        if let obj = value as? [String: Any], let encoded = jsonString(obj) {
            return encoded
        }

        if JSONSerialization.isValidJSONObject(["input": value]),
           let encoded = jsonString(["input": value]) {
            return encoded
        }
        return "{}"
    }

    private static func jsonString(_ object: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    private static func nsEqual(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        NSDictionary(dictionary: a).isEqual(to: b)
    }
}
