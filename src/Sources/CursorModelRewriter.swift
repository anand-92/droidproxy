import Foundation

/// Resolves Cursor catalog ids for the hosted Cursor API.
///
/// - Catalog entries use a `cursor-` prefix so ThinkingProxy routes to
///   `api-for-cursor.standardagents.ai` (not api.x.ai Grok OAuth).
/// - Upstream ids match standardagents/composer-api (`grok-4.6`, `grok-4.6-fast`, …).
enum CursorModelRewriter {
    static let host = "api-for-cursor.standardagents.ai"
    static let grok46Model = "grok-4.6"
    static let grok46FastModel = "grok-4.6-fast"

    /// Catalog id → upstream Cursor API model id.
    static let aliases: [String: String] = [
        "cursor-composer-2.5": "composer-2.5",
        "cursor-grok-4.6": grok46Model,
        "cursor-grok-4.6-fast": grok46FastModel
    ]

    /// Returns the upstream model id to send to the Cursor API.
    static func resolveUpstreamModel(_ catalogModel: String) -> String {
        aliases[catalogModel] ?? catalogModel
    }
}
