import XCTest
@testable import CLIProxyMenuBar

/// Guards the "Sequential account failover" setting, which works by rewriting
/// four values in the bundled `config.yaml`. Because that is a string
/// substitution, the anchors silently stop matching if the YAML is reformatted.
/// These tests fail loudly instead.
final class AccountFailoverConfigTests: XCTestCase {

    /// The bundled config as checked into the repo. Resolved from `#filePath`
    /// so the test reads the real file rather than a copy that can drift.
    private func bundledConfig() throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let srcRoot = testFile
            .deletingLastPathComponent()  // CLIProxyMenuBarTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // src
        let configURL = srcRoot
            .appendingPathComponent("Sources/Resources/config.yaml")
        return try String(contentsOf: configURL, encoding: .utf8)
    }

    // MARK: - Default

    /// Sequential failover is opt-in: it changes cooldown behavior for every
    /// provider, so an absent key must read as false and leave existing users
    /// on the historical round-robin routing.
    func testDefaultIsOff() {
        XCTAssertFalse(AppPreferences.defaultSequentialAccountFailover)

        UserDefaults.standard.removeObject(forKey: AppPreferences.sequentialAccountFailoverKey)
        XCTAssertFalse(AppPreferences.sequentialAccountFailover)
    }

    // MARK: - Transformation

    func testDisabledLeavesConfigUntouched() throws {
        let config = try bundledConfig()
        XCTAssertEqual(
            ServerManager.applyAccountFailoverOverrides(to: config, enabled: false),
            config
        )
    }

    func testEnabledAppliesEveryOverride() throws {
        let config = try bundledConfig()
        let updated = ServerManager.applyAccountFailoverOverrides(to: config, enabled: true)

        XCTAssertTrue(updated.contains("max-retry-interval: 30"))
        XCTAssertTrue(updated.contains("disable-cooling: false"))
        XCTAssertTrue(updated.contains("transient-error-cooldown-seconds: -1"))
        XCTAssertTrue(updated.contains("strategy: \"fill-first\""))

        // And none of the OFF values survive.
        XCTAssertFalse(updated.contains("max-retry-interval: 0"))
        XCTAssertFalse(updated.contains("disable-cooling: true"))
        XCTAssertFalse(updated.contains("transient-error-cooldown-seconds: 0"))
        XCTAssertFalse(updated.contains("strategy: \"round-robin\""))
    }

    /// The substitution table is only correct if each anchor appears exactly
    /// once in the bundled config. Zero occurrences means the override silently
    /// does nothing; more than one means an unrelated line gets rewritten.
    func testEveryAnchorAppearsExactlyOnceInBundledConfig() throws {
        let config = try bundledConfig()
        for rule in ServerManager.accountFailoverOverrides {
            XCTAssertEqual(
                config.components(separatedBy: rule.off).count - 1,
                1,
                "Anchor '\(rule.off)' must appear exactly once in config.yaml"
            )
        }
    }

    /// `getConfigPath()` also rewrites host, remote-management, and logging
    /// values by string match. The failover overrides must not disturb those.
    func testFailoverOverridesPreserveOtherConfigAnchors() throws {
        let config = try bundledConfig()
        let updated = ServerManager.applyAccountFailoverOverrides(to: config, enabled: true)

        let untouchedAnchors = [
            "host: 127.0.0.1",
            "  allow-remote: false",
            "  secret-key: \"\"  # Leave empty to disable management API",
            "debug: false",
            "logging-to-file: false"
        ]
        for anchor in untouchedAnchors {
            XCTAssertEqual(
                updated.components(separatedBy: anchor).count - 1,
                1,
                "Anchor '\(anchor)' must survive the failover overrides exactly once"
            )
        }
    }

    /// Session affinity is required for stateful Codex Responses traffic
    /// (issue #58) and must stay on in both states.
    func testSessionAffinityUnaffectedByOverrides() throws {
        let config = try bundledConfig()
        let updated = ServerManager.applyAccountFailoverOverrides(to: config, enabled: true)
        XCTAssertTrue(config.contains("session-affinity: true"))
        XCTAssertTrue(updated.contains("session-affinity: true"))
        XCTAssertTrue(updated.contains("session-affinity-ttl: \"2h\""))
    }

    /// Applying the overrides twice must be a no-op the second time, since
    /// `getConfigPath()` regenerates the merged config on every settings change.
    func testOverridesAreIdempotent() throws {
        let config = try bundledConfig()
        let once = ServerManager.applyAccountFailoverOverrides(to: config, enabled: true)
        let twice = ServerManager.applyAccountFailoverOverrides(to: once, enabled: true)
        XCTAssertEqual(once, twice)
    }
}
