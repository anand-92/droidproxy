import XCTest
@testable import CLIProxyMenuBar

final class DroidProxyModelCatalogTests: XCTestCase {
    func testFable5MatchesOpus48EffortLevels() throws {
        let fable = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:fable-5"))

        XCTAssertEqual(fable["model"] as? String, "claude-fable-5")
        XCTAssertEqual(fable["enableThinking"] as? Bool, true)
        XCTAssertEqual(fable["reasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(fable["defaultReasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(fable["supportedReasoningEfforts"] as? [String], ["low", "medium", "high", "xhigh", "max"])
        XCTAssertEqual(fable["maxOutputTokens"] as? Int, 128000)
    }

    func testSonnet5UsesNativeModelIDAndExposesFullLevels() throws {
        let sonnet = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:sonnet-5"))

        XCTAssertEqual(sonnet["model"] as? String, "claude-sonnet-5")
        XCTAssertEqual(sonnet["enableThinking"] as? Bool, true)
        XCTAssertEqual(sonnet["reasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(sonnet["defaultReasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(sonnet["supportedReasoningEfforts"] as? [String], ["low", "medium", "high", "xhigh", "max"])
    }

    func testGrok45UsesOpenAIProviderAndApiXAIProxy() throws {
        let grok = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:grok-4.5"))

        XCTAssertEqual(grok["model"] as? String, "grok-4.5")
        XCTAssertEqual(grok["provider"] as? String, "openai")
        XCTAssertEqual(grok["baseUrl"] as? String, "http://localhost:8317/v1")
        XCTAssertEqual(grok["displayName"] as? String, "DroidProxy: Grok 4.5")
        XCTAssertEqual(grok["supportedReasoningEfforts"] as? [String], ["low", "medium", "high", "xhigh"])
        XCTAssertEqual(grok["defaultReasoningEffort"] as? String, "high")
    }

    func testGrokProviderModelsAreRegistered() {
        let ids = DroidProxyModelCatalog.allSettingsIDs
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-4.5"))
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-4.3"))
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-build-0.1"))
    }

    private func settingsEntry(id: String) -> [String: Any]? {
        DroidProxyModelCatalog
            .settingsModels()
            .first { ($0["id"] as? String) == id }
    }
}
