import Foundation

/// Rewrites `Anthropic-Beta` on Claude requests.
///
/// CLIProxyAPI 7.2.130 treats any error as request-scoped when the header includes
/// `fast-mode-*`, which blocks OAuth seat failover on ordinary 5-hour 429s. Claude
/// has no Fast mode, so this rewriter never injects `fast-mode-*` and always strips
/// it if Factory/Droid sent it.
///
/// On thinking requests it also drops `redact-thinking-2026-02-12` and appends the
/// visible-thinking beta list so Claude emits plaintext thinking blocks.
enum ClaudeAnthropicBetaRewriter {
    static let redactedThinkingBeta = "redact-thinking-2026-02-12"

    static let visibleThinkingBetas = [
        "claude-code-20250219",
        "oauth-2025-04-20",
        "interleaved-thinking-2025-05-14",
        "context-management-2025-06-27",
        "prompt-caching-scope-2026-01-05",
        "structured-outputs-2025-12-15",
        "token-efficient-tools-2026-03-28"
    ]

    static func isFastModeBeta(_ rawBeta: String) -> Bool {
        rawBeta.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .hasPrefix("fast-mode-")
    }

    static func rewrite(_ headers: [(String, String)], requestVisibleThinking: Bool) -> [(String, String)] {
        if requestVisibleThinking {
            return headersWithVisibleThinkingBetas(headers)
        }
        return headersStrippingFastMode(headers)
    }

    private static func headersWithVisibleThinkingBetas(_ headers: [(String, String)]) -> [(String, String)] {
        var forwardedHeaders: [(String, String)] = []
        var betaCandidates: [String] = []

        for (name, value) in headers {
            if name.caseInsensitiveCompare("anthropic-beta") == .orderedSame {
                betaCandidates.append(contentsOf: parseAnthropicBetas(value))
                continue
            }
            forwardedHeaders.append((name, value))
        }

        betaCandidates.append(contentsOf: visibleThinkingBetas)

        var seen = Set<String>()
        let visibleBetas = betaCandidates.compactMap { rawBeta -> String? in
            let beta = rawBeta.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !beta.isEmpty else { return nil }
            let normalizedBeta = beta.lowercased()
            guard normalizedBeta != redactedThinkingBeta else { return nil }
            guard !isFastModeBeta(beta) else { return nil }
            guard !seen.contains(normalizedBeta) else { return nil }
            seen.insert(normalizedBeta)
            return beta
        }

        if !visibleBetas.isEmpty {
            forwardedHeaders.append(("Anthropic-Beta", visibleBetas.joined(separator: ",")))
        }
        return forwardedHeaders
    }

    /// Surgical: rewrite `Anthropic-Beta` only when a `fast-mode-*` token is present.
    private static func headersStrippingFastMode(_ headers: [(String, String)]) -> [(String, String)] {
        var didChange = false
        let rewritten: [(String, String)] = headers.compactMap { name, value in
            guard name.caseInsensitiveCompare("anthropic-beta") == .orderedSame else {
                return (name, value)
            }

            let parts = parseAnthropicBetas(value)
            guard parts.contains(where: { isFastModeBeta($0) }) else {
                return (name, value)
            }

            didChange = true
            let kept = parts.compactMap { raw -> String? in
                let beta = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !beta.isEmpty, !isFastModeBeta(beta) else { return nil }
                return beta
            }
            if kept.isEmpty {
                return nil
            }
            return (name, kept.joined(separator: ","))
        }
        return didChange ? rewritten : headers
    }

    private static func parseAnthropicBetas(_ value: String) -> [String] {
        value.split(separator: ",").map { String($0) }
    }
}
