import XCTest
@testable import CLIProxyMenuBar

final class ClaudeAnthropicBetaRewriterTests: XCTestCase {
    private let inboundFastModeHeader = (
        "Anthropic-Beta",
        "claude-code-20250219,fast-mode-2026-02-01,redact-thinking-2026-02-12,interleaved-thinking-2025-05-14"
    )

    func testThinkingAdaptiveStripsInboundFastModeAndDoesNotInjectIt() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [inboundFastModeHeader, ("X-Request-Id", "abc")],
            requestVisibleThinking: true
        )

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertTrue(containsBeta(rewritten, "interleaved-thinking-2025-05-14"))
        XCTAssertTrue(containsBeta(rewritten, "prompt-caching-scope-2026-01-05"))
        XCTAssertEqual(headerValue(rewritten, "X-Request-Id"), "abc")
    }

    func testThinkingEnabledStripsFastMode20260212() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [("anthropic-beta", "fast-mode-2026-02-12,oauth-2025-04-20")],
            requestVisibleThinking: true
        )

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertTrue(containsBeta(rewritten, "oauth-2025-04-20"))
    }

    func testThinkingAutoWithoutInboundFastModeDoesNotInjectIt() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [("Anthropic-Beta", "oauth-2025-04-20")],
            requestVisibleThinking: true
        )

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertFalse(ClaudeAnthropicBetaRewriter.visibleThinkingBetas.contains(where: {
            ClaudeAnthropicBetaRewriter.isFastModeBeta($0)
        }))
    }

    func testThinkingStripsRedactThinkingAndKeepsOtherVisibleBetas() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [inboundFastModeHeader],
            requestVisibleThinking: true
        )

        XCTAssertFalse(containsBeta(rewritten, ClaudeAnthropicBetaRewriter.redactedThinkingBeta))
        for beta in ClaudeAnthropicBetaRewriter.visibleThinkingBetas {
            XCTAssertTrue(containsBeta(rewritten, beta), "missing visible-thinking beta \(beta)")
        }
        XCTAssertFalse(containsFastMode(rewritten))
    }

    func testNonThinkingClaudeRequestUnchangedWhenNoFastMode() {
        let headers = [
            ("Anthropic-Beta", "oauth-2025-04-20,redact-thinking-2026-02-12"),
            ("X-Request-Id", "abc")
        ]

        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(headers, requestVisibleThinking: false)

        XCTAssertEqual(rewritten.map(\.0), headers.map(\.0))
        XCTAssertEqual(rewritten.map(\.1), headers.map(\.1))
        XCTAssertTrue(containsBeta(rewritten, "redact-thinking-2026-02-12"))
        XCTAssertFalse(containsBeta(rewritten, "prompt-caching-scope-2026-01-05"))
        XCTAssertFalse(containsFastMode(rewritten))
    }

    func testNonThinkingStripsInboundFastModeAndLeavesOtherBetas() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [inboundFastModeHeader, ("X-Request-Id", "abc")],
            requestVisibleThinking: false
        )

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertTrue(containsBeta(rewritten, "claude-code-20250219"))
        XCTAssertTrue(containsBeta(rewritten, "redact-thinking-2026-02-12"))
        XCTAssertTrue(containsBeta(rewritten, "interleaved-thinking-2025-05-14"))
        XCTAssertEqual(headerValue(rewritten, "X-Request-Id"), "abc")
        XCTAssertFalse(containsBeta(rewritten, "prompt-caching-scope-2026-01-05"))
    }

    func testNonThinkingDropsAnthropicBetaHeaderWhenOnlyFastModeWasPresent() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite(
            [("Anthropic-Beta", "fast-mode-2026-02-01"), ("Accept", "application/json")],
            requestVisibleThinking: false
        )

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertNil(headerValue(rewritten, "Anthropic-Beta"))
        XCTAssertEqual(headerValue(rewritten, "Accept"), "application/json")
    }

    func testThinkingWithNoInboundBetaStillOmitsFastMode() {
        let rewritten = ClaudeAnthropicBetaRewriter.rewrite([], requestVisibleThinking: true)

        XCTAssertFalse(containsFastMode(rewritten))
        XCTAssertTrue(containsBeta(rewritten, "interleaved-thinking-2025-05-14"))
        XCTAssertTrue(containsBeta(rewritten, "prompt-caching-scope-2026-01-05"))
        XCTAssertFalse(containsBeta(rewritten, ClaudeAnthropicBetaRewriter.redactedThinkingBeta))
    }

    private func containsFastMode(_ headers: [(String, String)]) -> Bool {
        anthropicBetas(from: headers).contains(where: ClaudeAnthropicBetaRewriter.isFastModeBeta)
    }

    private func containsBeta(_ headers: [(String, String)], _ expected: String) -> Bool {
        anthropicBetas(from: headers).contains { $0.caseInsensitiveCompare(expected) == .orderedSame }
    }

    private func headerValue(_ headers: [(String, String)], _ name: String) -> String? {
        headers.first { $0.0.caseInsensitiveCompare(name) == .orderedSame }?.1
    }

    private func anthropicBetas(from headers: [(String, String)]) -> [String] {
        headers
            .filter { $0.0.caseInsensitiveCompare("anthropic-beta") == .orderedSame }
            .flatMap { $0.1.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
            .filter { !$0.isEmpty }
    }
}
