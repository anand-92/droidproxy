import XCTest
@testable import CLIProxyMenuBar

final class AppPreferencesFastModeDefaultsTests: XCTestCase {
    /// Fast Mode is opt-in for Codex GPT. Absent keys
    /// must read as false so the Settings checkboxes start unchecked.
    func testAllFastModeDefaultsAreOff() {
        XCTAssertFalse(AppPreferences.defaultGpt54FastMode)
        XCTAssertFalse(AppPreferences.defaultGpt55FastMode)
        XCTAssertFalse(AppPreferences.defaultGpt56TerraFastMode)
        XCTAssertFalse(AppPreferences.defaultGpt56LunaFastMode)
        XCTAssertFalse(AppPreferences.defaultGpt56SolFastMode)
    }

    func testUnsetFastModeKeysReadAsFalse() {
        let defaults = UserDefaults.standard
        let keys = [
            AppPreferences.gpt54FastModeKey,
            AppPreferences.gpt55FastModeKey,
            AppPreferences.gpt56TerraFastModeKey,
            AppPreferences.gpt56LunaFastModeKey,
            AppPreferences.gpt56SolFastModeKey
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        XCTAssertFalse(AppPreferences.gpt54FastMode)
        XCTAssertFalse(AppPreferences.gpt55FastMode)
        XCTAssertFalse(AppPreferences.gpt56TerraFastMode)
        XCTAssertFalse(AppPreferences.gpt56LunaFastMode)
        XCTAssertFalse(AppPreferences.gpt56SolFastMode)
    }
}
