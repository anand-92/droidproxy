import XCTest
@testable import CLIProxyMenuBar

final class CursorModelRewriterTests: XCTestCase {
    func testAliasesMapCatalogIdsToUpstreamCursorModels() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-composer-2.5", grok45FastMode: false),
            "composer-2.5"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5", grok45FastMode: false),
            "grok-4.5"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5-fast", grok45FastMode: false),
            "grok-4.5-fast"
        )
    }

    func testFastModeRewritesGrok45ToFast() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5", grok45FastMode: true),
            "grok-4.5-fast"
        )
        // Explicit Fast catalog entry stays fast regardless of the checkbox.
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.5-fast", grok45FastMode: true),
            "grok-4.5-fast"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-composer-2.5", grok45FastMode: true),
            "composer-2.5"
        )
    }

    func testUnknownCursorIdsPassThrough() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-small", grok45FastMode: true),
            "cursor-small"
        )
    }

    func testHostPointsAtCurrentStandardAgentsAPI() {
        XCTAssertEqual(CursorModelRewriter.host, "api-for-cursor.standardagents.ai")
    }
}
