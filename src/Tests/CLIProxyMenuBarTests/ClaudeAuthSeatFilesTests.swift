import XCTest
@testable import CLIProxyMenuBar

final class ClaudeAuthSeatFilesTests: XCTestCase {
    private let email = "josef@kaikaku.ai"
    private let personalUUID = "01a2b962-674f-47df-afdd-fc21609e4987"
    private let teamUUID = "b305c0b8-71d7-4d4c-8cab-47e9f78eea3e"

    private var scratch: URL!

    override func setUp() {
        super.setUp()
        scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("claude-seat-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratch)
        scratch = nil
        super.tearDown()
    }

    // MARK: - Org field parsing

    func testParsesTopLevelOrganizationFields() {
        let fields = ClaudeAuthSeatFiles.organizationFields(from: [
            "organization_uuid": personalUUID,
            "organization_name": "Josef Chen"
        ])
        XCTAssertEqual(fields.uuid, personalUUID)
        XCTAssertEqual(fields.name, "Josef Chen")
        XCTAssertTrue(fields.hasSeatIdentity)
    }

    func testParsesNestedOrganizationObject() {
        let fields = ClaudeAuthSeatFiles.organizationFields(from: [
            "organization": [
                "uuid": teamUUID,
                "name": "KAIKAKU"
            ]
        ])
        XCTAssertEqual(fields.uuid, teamUUID)
        XCTAssertEqual(fields.name, "KAIKAKU")
    }

    func testBlankOrganizationFieldsAreMissing() {
        let fields = ClaudeAuthSeatFiles.organizationFields(from: [
            "organization_uuid": "  ",
            "organization_name": ""
        ])
        XCTAssertNil(fields.uuid)
        XCTAssertNil(fields.name)
        XCTAssertFalse(fields.hasSeatIdentity)
    }

    // MARK: - Display labels

    func testPersonStyleNameIsPersonalMax() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: "Josef Chen"),
            "Personal Max"
        )
    }

    func testAllCapsOrgIsTeam() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: "KAIKAKU"),
            "KAIKAKU (Team)"
        )
    }

    func testCompanySuffixIsTeam() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: "Acme Inc"),
            "Acme Inc (Team)"
        )
    }

    func testAmbiguousNameIsShownRaw() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: "Pessoal"),
            "Pessoal"
        )
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: "Acme"),
            "Acme"
        )
    }

    func testEmailPossessiveOrganizationIsPersonalMax() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(
                email: email,
                organizationName: "josef@kaikaku.ai's Organization"
            ),
            "Personal Max"
        )
    }

    func testExplicitOrganizationTypeWinsOverName() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, json: [
                "organization_name": "Pessoal",
                "organization_type": "claude_max"
            ]),
            "Personal Max"
        )
        XCTAssertEqual(
            ClaudeAuthSeatFiles.seatDisplayLabel(email: email, json: [
                "organization_name": "Josef Chen",
                "organization_type": "claude_team"
            ]),
            "Josef Chen (Team)"
        )
    }

    func testMissingOrganizationNameYieldsNoSuffix() {
        XCTAssertNil(ClaudeAuthSeatFiles.seatDisplayLabel(email: email, organizationName: nil))
    }

    func testSettingsRowShowsEmailAndClassifiedLabel() {
        let personal = AuthAccount(
            id: "claude-\(email)-\(personalUUID).json",
            email: email,
            login: nil,
            type: .claude,
            expired: nil,
            filePath: scratch.appendingPathComponent("personal.json"),
            isDisabled: false,
            organizationName: "Josef Chen",
            claudeSeatLabel: ClaudeAuthSeatFiles.seatDisplayLabel(
                email: email,
                organizationName: "Josef Chen"
            )
        )
        let team = AuthAccount(
            id: "claude-\(email)-\(teamUUID).json",
            email: email,
            login: nil,
            type: .claude,
            expired: nil,
            filePath: scratch.appendingPathComponent("team.json"),
            isDisabled: false,
            organizationName: "KAIKAKU",
            claudeSeatLabel: ClaudeAuthSeatFiles.seatDisplayLabel(
                email: email,
                organizationName: "KAIKAKU"
            )
        )

        XCTAssertEqual(personal.displayName, "\(email) · Personal Max")
        XCTAssertEqual(team.displayName, "\(email) · KAIKAKU (Team)")
    }

    func testMissingLabelShowsEmailOnly() {
        let account = AuthAccount(
            id: "claude-\(email).json",
            email: email,
            login: nil,
            type: .claude,
            expired: nil,
            filePath: scratch.appendingPathComponent("plain.json"),
            isDisabled: false,
            organizationName: nil,
            claudeSeatLabel: nil
        )
        XCTAssertEqual(account.displayName, email)
    }

    // MARK: - Filenames

    func testUniqueFilenamePrefersUUID() {
        let name = ClaudeAuthSeatFiles.uniqueFilename(
            email: email,
            fields: .init(uuid: personalUUID, name: "Josef Chen")
        )
        XCTAssertEqual(name, "claude-\(email)-\(personalUUID).json")
    }

    func testCanonicalFilenameMatchesCLIProxyAPI() {
        XCTAssertEqual(
            ClaudeAuthSeatFiles.canonicalFilename(email: email),
            "claude-\(email).json"
        )
        XCTAssertTrue(
            ClaudeAuthSeatFiles.isCanonicalClaudeEmailFile("claude-\(email).json", email: email)
        )
        XCTAssertFalse(
            ClaudeAuthSeatFiles.isCanonicalClaudeEmailFile("claude-\(email)-kaikaku.json", email: email)
        )
    }

    // MARK: - Rename / collision

    func testTwoOrgsSameEmailBecomeTwoUUIDFiles() throws {
        try writeClaudeFile(
            named: "claude-\(email).json",
            email: email,
            orgName: "Josef Chen",
            orgUUID: personalUUID,
            marker: "personal-token"
        )
        XCTAssertNotNil(ClaudeAuthSeatFiles.migrateFile(at: scratch.appendingPathComponent("claude-\(email).json")))

        try writeClaudeFile(
            named: "claude-\(email).json",
            email: email,
            orgName: "KAIKAKU",
            orgUUID: teamUUID,
            marker: "team-token"
        )
        XCTAssertNotNil(ClaudeAuthSeatFiles.migrateFile(at: scratch.appendingPathComponent("claude-\(email).json")))

        let names = jsonNames()
        XCTAssertFalse(names.contains("claude-\(email).json"))
        XCTAssertTrue(names.contains("claude-\(email)-\(personalUUID).json"))
        XCTAssertTrue(names.contains("claude-\(email)-\(teamUUID).json"))
        XCTAssertEqual(marker(in: "claude-\(email)-\(personalUUID).json"), "personal-token")
        XCTAssertEqual(marker(in: "claude-\(email)-\(teamUUID).json"), "team-token")
    }

    func testReauthSameOrgRefreshesUUIDFileOnly() throws {
        try writeClaudeFile(
            named: "claude-\(email)-\(personalUUID).json",
            email: email,
            orgName: "Josef Chen",
            orgUUID: personalUUID,
            marker: "old-personal"
        )
        try writeClaudeFile(
            named: "claude-\(email)-\(teamUUID).json",
            email: email,
            orgName: "KAIKAKU",
            orgUUID: teamUUID,
            marker: "team-token"
        )
        try writeClaudeFile(
            named: "claude-\(email).json",
            email: email,
            orgName: "Josef Chen",
            orgUUID: personalUUID,
            marker: "new-personal"
        )

        ClaudeAuthSeatFiles.migrateCanonicalFiles(in: scratch)

        let names = jsonNames()
        XCTAssertFalse(names.contains("claude-\(email).json"))
        XCTAssertEqual(marker(in: "claude-\(email)-\(personalUUID).json"), "new-personal")
        XCTAssertEqual(marker(in: "claude-\(email)-\(teamUUID).json"), "team-token")
    }

    func testMissingOrgFieldsLeaveCanonicalName() throws {
        try writeJSON(
            named: "claude-\(email).json",
            [
                "type": "claude",
                "email": email,
                "access_token": "x"
            ]
        )

        XCTAssertNil(ClaudeAuthSeatFiles.migrateFile(at: scratch.appendingPathComponent("claude-\(email).json")))
        XCTAssertEqual(jsonNames(), ["claude-\(email).json"])
    }

    func testAlreadySuffixedNameMigratesToUUID() throws {
        try writeClaudeFile(
            named: "claude-\(email)-kaikaku.json",
            email: email,
            orgName: "KAIKAKU",
            orgUUID: teamUUID,
            marker: "team-token"
        )

        ClaudeAuthSeatFiles.migrateCanonicalFiles(in: scratch)

        let names = jsonNames()
        XCTAssertFalse(names.contains("claude-\(email)-kaikaku.json"))
        XCTAssertTrue(names.contains("claude-\(email)-\(teamUUID).json"))
        XCTAssertEqual(marker(in: "claude-\(email)-\(teamUUID).json"), "team-token")
    }

    func testEmptyAndIncompleteJSONAreLeftAlone() throws {
        let empty = scratch.appendingPathComponent("claude-\(email).json")
        FileManager.default.createFile(atPath: empty.path, contents: Data(), attributes: nil)
        XCTAssertNil(ClaudeAuthSeatFiles.migrateFile(at: empty))
        XCTAssertTrue(FileManager.default.fileExists(atPath: empty.path))

        try "{".write(to: empty, atomically: true, encoding: .utf8)
        XCTAssertNil(ClaudeAuthSeatFiles.migrateFile(at: empty))
        XCTAssertEqual(try String(contentsOf: empty, encoding: .utf8), "{")
    }

    func testCodexAndOtherProvidersAreNotRenamed() throws {
        try writeJSON(
            named: "codex-\(email).json",
            [
                "type": "codex",
                "email": email,
                "organization_uuid": personalUUID,
                "organization_name": "Josef Chen"
            ]
        )
        try writeJSON(
            named: "gemini-\(email).json",
            [
                "type": "gemini",
                "email": email,
                "organization_uuid": personalUUID
            ]
        )

        ClaudeAuthSeatFiles.migrateCanonicalFiles(in: scratch)

        XCTAssertEqual(Set(jsonNames()), [
            "codex-\(email).json",
            "gemini-\(email).json"
        ])
    }

    // MARK: - Scratch helpers

    private func writeClaudeFile(
        named: String,
        email: String,
        orgName: String,
        orgUUID: String,
        marker: String
    ) throws {
        try writeJSON(named: named, [
            "type": "claude",
            "email": email,
            "organization_name": orgName,
            "organization_uuid": orgUUID,
            "access_token": marker
        ])
    }

    private func writeJSON(named: String, _ object: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try data.write(to: scratch.appendingPathComponent(named), options: .atomic)
    }

    private func jsonNames() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: scratch.path)) ?? [])
            .filter { $0.hasSuffix(".json") }
            .sorted()
    }

    private func marker(in filename: String) -> String? {
        let url = scratch.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["access_token"] as? String
    }
}
