import XCTest
@testable import CLIProxyMenuBar

final class CursorModelRewriterTests: XCTestCase {
    func testAliasesMapCatalogIdsToUpstreamCursorModels() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-composer-2.5", grok46FastMode: false),
            "composer-2.5"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.6", grok46FastMode: false),
            "grok-4.6"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.6-fast", grok46FastMode: false),
            "grok-4.6-fast"
        )
    }

    func testFastModeRewritesGrok46ToFast() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.6", grok46FastMode: true),
            "grok-4.6-fast"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("grok-4.6", grok46FastMode: true),
            "grok-4.6-fast"
        )
        // Explicit Fast catalog entry stays fast regardless of the checkbox.
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-grok-4.6-fast", grok46FastMode: true),
            "grok-4.6-fast"
        )
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-composer-2.5", grok46FastMode: true),
            "composer-2.5"
        )
    }

    func testGrokOAuthFastDivertPredicate() {
        XCTAssertTrue(
            CursorModelRewriter.shouldDivertGrokOAuthToCursorFast(model: "grok-4.6", grok46FastMode: true)
        )
        XCTAssertFalse(
            CursorModelRewriter.shouldDivertGrokOAuthToCursorFast(model: "grok-4.6", grok46FastMode: false)
        )
        XCTAssertFalse(
            CursorModelRewriter.shouldDivertGrokOAuthToCursorFast(model: "grok-4.5", grok46FastMode: true)
        )
    }

    func testUnknownCursorIdsPassThrough() {
        XCTAssertEqual(
            CursorModelRewriter.resolveUpstreamModel("cursor-small", grok46FastMode: true),
            "cursor-small"
        )
    }

    func testHostPointsAtCurrentStandardAgentsAPI() {
        XCTAssertEqual(CursorModelRewriter.host, "api-for-cursor.standardagents.ai")
    }
}
