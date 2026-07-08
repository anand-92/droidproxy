import Foundation

/// Sanitizes Factory/Droid `/v1/responses` bodies before forwarding to api.x.ai.
///
/// xAI rejects OpenAI-style `"type":"custom"` tools with HTTP 422
/// (`unknown variant custom, expected one of function, web_search, …`).
/// Client tools are remapped to `"function"`; anything outside the allowlist
/// is dropped. Nested chat-completions function wrappers are flattened.
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

        return flat
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

    private static func nsEqual(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        NSDictionary(dictionary: a).isEqual(to: b)
    }
}
