import XCTest
@testable import CLIProxyMenuBar

final class GrokRequestSanitizerTests: XCTestCase {
    func testRemapsCustomToolToFunction() throws {
        let request = """
        {"model":"grok-4.6","input":"hi","tools":[{"type":"custom","name":"Read","description":"Read a file","parameters":{"type":"object","properties":{"path":{"type":"string"}}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["type"] as? String, "function")
        XCTAssertEqual(tools[0]["name"] as? String, "Read")
        XCTAssertEqual(tools[0]["description"] as? String, "Read a file")
        XCTAssertNotNil(tools[0]["parameters"] as? [String: Any])
        XCTAssertFalse(sanitized.contains("\"type\":\"custom\""))
    }

    func testFlattensChatCompletionsFunctionWrapper() throws {
        let request = """
        {"model":"grok-4.6","tools":[{"type":"function","function":{"name":"Bash","description":"Run","parameters":{"type":"object","properties":{}}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["type"] as? String, "function")
        XCTAssertEqual(tools[0]["name"] as? String, "Bash")
        XCTAssertNil(tools[0]["function"])
    }

    func testKeepsBuiltinSearchTools() throws {
        let request = """
        {"model":"grok-4.6","tools":[{"type":"web_search"},{"type":"x_search"},{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 3)
        XCTAssertEqual(tools[0]["type"] as? String, "web_search")
        XCTAssertEqual(tools[1]["type"] as? String, "x_search")
        XCTAssertEqual(tools[2]["type"] as? String, "function")
    }

    func testDropsUnknownToolTypes() throws {
        let request = """
        {"model":"grok-4.6","tools":[{"type":"computer_use_preview"},{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["name"] as? String, "Read")
    }

    func testRemovesToolsKeyWhenAllDropped() throws {
        let request = """
        {"model":"grok-4.6","input":"hi","tools":[{"type":"computer_use_preview"}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        XCTAssertNil(root["tools"])
        XCTAssertEqual(root["model"] as? String, "grok-4.6")
    }

    func testLeavesBodyWithoutToolsUnchanged() {
        let request = #"{"model":"grok-4.6","input":"hello"}"#
        XCTAssertEqual(GrokRequestSanitizer.sanitize(request), request)
    }

    func testRewritesCustomToolChoice() throws {
        let request = """
        {"model":"grok-4.6","tool_choice":{"type":"custom","name":"Read"},"tools":[{"type":"custom","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let choice = try XCTUnwrap(root["tool_choice"] as? [String: Any])
        XCTAssertEqual(choice["type"] as? String, "function")
        XCTAssertEqual(choice["name"] as? String, "Read")
    }

    func testFlattensNestedFunctionToolChoice() throws {
        let request = """
        {"model":"grok-4.6","tool_choice":{"type":"function","function":{"name":"Read"}},"tools":[{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let choice = try XCTUnwrap(root["tool_choice"] as? [String: Any])
        XCTAssertEqual(choice["type"] as? String, "function")
        XCTAssertEqual(choice["name"] as? String, "Read")
        XCTAssertNil(choice["function"])
    }

    func testMapsInputSchemaToParameters() throws {
        let request = """
        {"model":"grok-4.6","tools":[{"type":"custom","name":"Read","input_schema":{"type":"object","properties":{"path":{"type":"string"}}}}]}
        """
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        let parameters = try XCTUnwrap(tools[0]["parameters"] as? [String: Any])
        XCTAssertEqual(parameters["type"] as? String, "object")
        XCTAssertNotNil(parameters["properties"] as? [String: Any])
        XCTAssertNil(tools[0]["input_schema"])
    }

    func testDropsNamelessCustomToolAndDefaultsEmptyParameters() throws {
        let request = """
        {"model":"grok-4.6","tools":[{"type":"custom","description":"no name"},{"type":"function","name":"Bare"}]}
        """
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["name"] as? String, "Bare")
        let parameters = try XCTUnwrap(tools[0]["parameters"] as? [String: Any])
        XCTAssertEqual(parameters["type"] as? String, "object")
    }

    func testLeavesInvalidJSONUnchanged() {
        let request = "{not-json"
        XCTAssertEqual(GrokRequestSanitizer.sanitize(request), request)
    }

    func testDropsOrphanedStringToolChoiceWithoutTools() throws {
        let request = #"{"model":"grok-4.6","tool_choice":"auto","parallel_tool_calls":true}"#
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        XCTAssertEqual(root["model"] as? String, "grok-4.6")
        XCTAssertNil(root["tool_choice"])
        XCTAssertNil(root["parallel_tool_calls"])
        XCTAssertNil(root["tools"])
    }

    func testConvertsCustomToolCallInputItems() throws {
        let request = """
        {"model":"grok-4.6","input":[{"role":"user","content":[{"type":"input_text","text":"hi"}]},{"type":"custom_tool_call","call_id":"c0","name":"ApplyPatch","input":"*** Begin Patch"},{"type":"custom_tool_call_output","call_id":"c0","output":"done"}],"tools":[],"tool_choice":"auto","parallel_tool_calls":true}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let input = try XCTUnwrap(root["input"] as? [[String: Any]])
        XCTAssertEqual(input.count, 3)
        XCTAssertEqual(input[1]["type"] as? String, "function_call")
        XCTAssertEqual(input[1]["name"] as? String, "ApplyPatch")
        XCTAssertEqual(input[1]["call_id"] as? String, "c0")
        XCTAssertNil(input[1]["input"])
        let arguments = try XCTUnwrap(input[1]["arguments"] as? String)
        let argsObj = try XCTUnwrap(jsonObject(arguments))
        XCTAssertEqual(argsObj["input"] as? String, "*** Begin Patch")
        XCTAssertEqual(input[2]["type"] as? String, "function_call_output")
        XCTAssertEqual(input[2]["output"] as? String, "done")
        XCTAssertNil(root["tools"])
        XCTAssertNil(root["tool_choice"])
        XCTAssertNil(root["parallel_tool_calls"])
    }

    func testCustomToolCallObjectInputBecomesArgumentsString() throws {
        let request = """
        {"model":"grok-4.6","input":[{"type":"custom_tool_call","call_id":"c1","name":"Read","input":{"file_path":"/tmp/a"}}]}
        """
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let input = try XCTUnwrap(root["input"] as? [[String: Any]])
        XCTAssertEqual(input[0]["type"] as? String, "function_call")
        let arguments = try XCTUnwrap(input[0]["arguments"] as? String)
        let argsObj = try XCTUnwrap(jsonObject(arguments))
        XCTAssertEqual(argsObj["file_path"] as? String, "/tmp/a")
    }

    func testLeavesExistingFunctionCallInputUnchanged() throws {
        let request = #"{"model":"grok-4.6","input":[{"type":"function_call","call_id":"f0","name":"Read","arguments":"{}"}]}"#
        XCTAssertEqual(GrokRequestSanitizer.sanitize(request), request)
    }

    func testKeepsStringToolChoiceWhenToolsPresent() throws {
        let request = """
        {"model":"grok-4.6","tool_choice":"auto","tools":[{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """
        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        XCTAssertEqual(root["tool_choice"] as? String, "auto")
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
    }

    private func jsonObject(_ string: String) throws -> [String: Any] {
        let data = try XCTUnwrap(string.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(obj as? [String: Any])
    }
}
