import XCTest
@testable import CLIProxyMenuBar

final class GrokRequestSanitizerTests: XCTestCase {
    func testRemapsCustomToolToFunction() throws {
        let request = """
        {"model":"grok-4.5","input":"hi","tools":[{"type":"custom","name":"Read","description":"Read a file","parameters":{"type":"object","properties":{"path":{"type":"string"}}}}]}
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
        {"model":"grok-4.5","tools":[{"type":"function","function":{"name":"Bash","description":"Run","parameters":{"type":"object","properties":{}}}}]}
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
        {"model":"grok-4.5","tools":[{"type":"web_search"},{"type":"x_search"},{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
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
        {"model":"grok-4.5","tools":[{"type":"computer_use_preview"},{"type":"function","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let tools = try XCTUnwrap(root["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["name"] as? String, "Read")
    }

    func testRemovesToolsKeyWhenAllDropped() throws {
        let request = """
        {"model":"grok-4.5","input":"hi","tools":[{"type":"computer_use_preview"}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        XCTAssertNil(root["tools"])
        XCTAssertEqual(root["model"] as? String, "grok-4.5")
    }

    func testLeavesBodyWithoutToolsUnchanged() {
        let request = #"{"model":"grok-4.5","input":"hello"}"#
        XCTAssertEqual(GrokRequestSanitizer.sanitize(request), request)
    }

    func testRewritesCustomToolChoice() throws {
        let request = """
        {"model":"grok-4.5","tool_choice":{"type":"custom","name":"Read"},"tools":[{"type":"custom","name":"Read","parameters":{"type":"object","properties":{}}}]}
        """

        let sanitized = GrokRequestSanitizer.sanitize(request)
        let root = try XCTUnwrap(jsonObject(sanitized))
        let choice = try XCTUnwrap(root["tool_choice"] as? [String: Any])
        XCTAssertEqual(choice["type"] as? String, "function")
        XCTAssertEqual(choice["name"] as? String, "Read")
    }

    private func jsonObject(_ string: String) throws -> [String: Any] {
        let data = try XCTUnwrap(string.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(obj as? [String: Any])
    }
}
