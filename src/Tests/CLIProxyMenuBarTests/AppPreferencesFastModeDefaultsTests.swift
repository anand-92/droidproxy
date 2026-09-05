import XCTest
@testable import CLIProxyMenuBar

final class AppPreferencesFastModeDefaultsTests: XCTestCase {
    /// Fast Mode is opt-in for every provider (Codex GPT + Grok). Absent keys
    /// must read as false so the Settings checkboxes start unchecked.
    func testAllFastModeDefaultsAreOff() {
        XCTAssertFalse(AppPreferences.defaultGpt56TerraFastMode)
        XCTAssertFalse(AppPreferences.defaultGpt56LunaFastMode)
        XCTAssertFalse(AppPreferences.defaultGpt56SolFastMode)
        XCTAssertFalse(AppPreferences.defaultGpt6AstraFastMode)
        XCTAssertFalse(AppPreferences.defaultGrok46FastMode)
    }

    func testUnsetFastModeKeysReadAsFalse() {
        let defaults = UserDefaults.standard
        let keys = [
            AppPreferences.gpt56TerraFastModeKey,
            AppPreferences.gpt56LunaFastModeKey,
            AppPreferences.gpt56SolFastModeKey,
            AppPreferences.gpt6AstraFastModeKey,
            AppPreferences.grok46FastModeKey
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        XCTAssertFalse(AppPreferences.gpt56TerraFastMode)
        XCTAssertFalse(AppPreferences.gpt56LunaFastMode)
        XCTAssertFalse(AppPreferences.gpt56SolFastMode)
        XCTAssertFalse(AppPreferences.gpt6AstraFastMode)
        XCTAssertFalse(AppPreferences.grok46FastMode)
    }
}
