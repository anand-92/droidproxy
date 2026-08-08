import XCTest
@testable import CLIProxyMenuBar

final class CursorModelRewriterTests: XCTestCase {
    func testAliasesMapCatalogIdsToUpstreamCursorModels() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-composer-2.5"),
            "composer-2.5"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5"),
            "grok-4.5"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5-fast"),
            "grok-4.5-fast"
        )
    }

    func testUnknownCursorIdsPassThrough() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-small"),
            "cursor-small"
        )
    }

    func testHostPointsAtCurrentStandardAgentsAPI() {
        XCTAssertEqual(CursorModelRewriter.host, "api-for-cursor.standardagents.ai")
    }
}
