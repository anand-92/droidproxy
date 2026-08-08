import Foundation

/// Resolves Cursor catalog ids for the hosted Cursor API.
///
/// - Catalog entries use a `cursor-` prefix so ThinkingProxy routes to
///   `api-for-cursor.standardagents.ai` (not api.x.ai Grok OAuth).
/// - Upstream ids match standardagents/composer-api (`grok-4.5`, `grok-4.5-fast`, …).
enum CursorModelRewriter {
    static let host = "api-for-cursor.standardagents.ai"
    static let grok45Model = "grok-4.5"
    static let grok45FastModel = "grok-4.5-fast"

    /// Catalog id → upstream Cursor API model id.
    static let aliases: [String: String] = [
        "cursor-composer-2.5": "composer-2.5",
        "cursor-grok-4.5": grok45Model,
        "cursor-grok-4.5-fast": grok45FastModel
    ]

    /// Returns the upstream model id to send to the Cursor API.
    static func resolveUpstreamModel(_ catalogModel: String) -> String {
        aliases[catalogModel] ?? catalogModel
    }
}
