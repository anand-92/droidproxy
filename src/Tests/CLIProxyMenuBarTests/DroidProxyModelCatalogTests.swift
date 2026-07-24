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

    func testApplyWritesBothOpus5AndOpus48ForClaudeProvider() throws {
        // Apply/Re-apply serializes every enabled definition via settingsModels();
        // both Opus entries are providerKey "claude", so enabling Claude writes both.
        let claudeModels = DroidProxyModelCatalog.settingsModels { $0 == "claude" }
        let ids = Set(claudeModels.compactMap { $0["id"] as? String })
        XCTAssertTrue(ids.contains("custom:droidproxy:opus-5"))
        XCTAssertTrue(ids.contains("custom:droidproxy:opus-4-8"))

        let opus5 = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:opus-5"))
        XCTAssertEqual(opus5["model"] as? String, "claude-opus-5")
        XCTAssertEqual(opus5["displayName"] as? String, "DroidProxy: Opus 5")

        let opus48 = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:opus-4-8"))
        XCTAssertEqual(opus48["model"] as? String, "claude-opus-4-8")
        XCTAssertEqual(opus48["displayName"] as? String, "DroidProxy: Opus 4.8")

        // Non-Junie only: the junie provider exposes Opus 5 but not Opus 4.8.
        let junieIds = Set(DroidProxyModelCatalog.settingsModels { $0 == "junie" }
            .compactMap { $0["id"] as? String })
        XCTAssertTrue(junieIds.contains("custom:droidproxy:junie-claude-opus-5"))
        XCTAssertFalse(junieIds.contains("custom:droidproxy:junie-claude-opus-4-8"))
    }

    func testSonnet5UsesNativeModelIDAndExposesFullLevels() throws {
        let sonnet = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:sonnet-5"))

        XCTAssertEqual(sonnet["model"] as? String, "claude-sonnet-5")
        XCTAssertEqual(sonnet["enableThinking"] as? Bool, true)
        XCTAssertEqual(sonnet["reasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(sonnet["defaultReasoningEffort"] as? String, "xhigh")
        XCTAssertEqual(sonnet["supportedReasoningEfforts"] as? [String], ["low", "medium", "high", "xhigh", "max"])
    }

    func testGpt56LunaUsesNativeModelMetadata() throws {
        let luna = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:gpt-5.6-luna"))

        XCTAssertEqual(luna["model"] as? String, "gpt-5.6-luna")
        XCTAssertEqual(luna["provider"] as? String, "openai")
        XCTAssertEqual(luna["baseUrl"] as? String, "http://localhost:8317/v1")
        XCTAssertEqual(luna["displayName"] as? String, "DroidProxy: GPT 5.6 Luna")
        XCTAssertEqual(luna["maxOutputTokens"] as? Int, 128000)
        XCTAssertEqual(luna["enableThinking"] as? Bool, true)
        XCTAssertEqual(luna["reasoningEffort"] as? String, "medium")
        XCTAssertEqual(luna["defaultReasoningEffort"] as? String, "medium")
        XCTAssertEqual(luna["supportedReasoningEfforts"] as? [String], ["none", "low", "medium", "high", "xhigh", "max"])
    }

    func testKimiK3UsesMaxReasoningMetadata() throws {
        let kimiK3 = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:kimi-k3"))

        XCTAssertEqual(kimiK3["model"] as? String, "kimi-k3")
        XCTAssertEqual(kimiK3["provider"] as? String, "openai")
        XCTAssertEqual(kimiK3["baseUrl"] as? String, "http://localhost:8317/v1")
        XCTAssertEqual(kimiK3["displayName"] as? String, "DroidProxy: Kimi K3")
        XCTAssertEqual(kimiK3["maxOutputTokens"] as? Int, 65536)
        XCTAssertEqual(kimiK3["enableThinking"] as? Bool, true)
        XCTAssertEqual(kimiK3["reasoningEffort"] as? String, "max")
        XCTAssertEqual(kimiK3["defaultReasoningEffort"] as? String, "max")
        XCTAssertEqual(kimiK3["supportedReasoningEfforts"] as? [String], ["max"])

        let modelsWithoutKimi = DroidProxyModelCatalog.settingsModels { $0 != "kimi" }
        XCTAssertFalse(modelsWithoutKimi.contains { ($0["id"] as? String) == "custom:droidproxy:kimi-k3" })
    }

    func testGrok45UsesOpenAIProviderAndApiXAIProxy() throws {
        let grok = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:grok-4.5"))

        XCTAssertEqual(grok["model"] as? String, "grok-4.5")
        XCTAssertEqual(grok["provider"] as? String, "openai")
        XCTAssertEqual(grok["baseUrl"] as? String, "http://localhost:8317/v1")
        XCTAssertEqual(grok["displayName"] as? String, "DroidProxy: Grok 4.5")
        XCTAssertEqual(grok["supportedReasoningEfforts"] as? [String], ["low", "medium", "high", "xhigh"])
        XCTAssertEqual(grok["defaultReasoningEffort"] as? String, "high")
        XCTAssertEqual(grok["maxContextLimit"] as? Int, 500_000)
    }

    func testGrokProviderModelsAreRegistered() {
        let ids = DroidProxyModelCatalog.allSettingsIDs
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-4.5"))
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-4.3"))
        XCTAssertTrue(ids.contains("custom:droidproxy:grok-build-0.1"))
    }

    func testGrokContextLimitsMatchXAIDocs() throws {
        let grok45 = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:grok-4.5"))
        let grok43 = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:grok-4.3"))
        let build = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:grok-build-0.1"))

        XCTAssertEqual(grok45["maxContextLimit"] as? Int, 500_000)
        XCTAssertEqual(grok43["maxContextLimit"] as? Int, 1_000_000)
        XCTAssertEqual(build["maxContextLimit"] as? Int, 256_000)
    }

    func testFactoryCompactionLimitsSitUnderGrokWindows() {
        let limits = DroidProxyModelCatalog.factoryCompactionTokenLimitPerModel
        XCTAssertEqual(limits["custom:droidproxy:grok-4.5"], 400_000)
        XCTAssertEqual(limits["custom:droidproxy:grok-4.3"], 800_000)
        XCTAssertEqual(limits["custom:droidproxy:grok-build-0.1"], 200_000)
    }

    func testCursorGrokModelsAppearWhenBetaEnabled() throws {
        let previous = BETA_FLAG
        BETA_FLAG = true
        defer { BETA_FLAG = previous }

        let standard = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:cursor-grok-4.5"))
        let fast = try XCTUnwrap(settingsEntry(id: "custom:droidproxy:cursor-grok-4.5-fast"))

        XCTAssertEqual(standard["model"] as? String, "cursor-grok-4.5")
        XCTAssertEqual(standard["provider"] as? String, "generic-chat-completion-api")
        XCTAssertEqual(standard["displayName"] as? String, "DroidProxy: Cursor Grok 4.5")
        XCTAssertEqual(fast["model"] as? String, "cursor-grok-4.5-fast")
        XCTAssertEqual(fast["displayName"] as? String, "DroidProxy: Cursor Grok 4.5 Fast")
    }

    private func settingsEntry(id: String) -> [String: Any]? {
        DroidProxyModelCatalog
            .settingsModels()
            .first { ($0["id"] as? String) == id }
    }
}
