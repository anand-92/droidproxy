import Foundation

/// Resolves Cursor catalog ids and Grok Fast Mode rewrites for the hosted Cursor API.
///
/// - Catalog entries use a `cursor-` prefix so ThinkingProxy routes to
///   `api-for-cursor.standardagents.ai` (not api.x.ai Grok OAuth).
/// - Upstream ids match standardagents/composer-api (`grok-4.5`, `grok-4.5-fast`, …).
/// - Fast Mode rewrites `grok-4.5` → `grok-4.5-fast` (model-id swap). api.x.ai does
///   **not** expose `grok-4.5-fast` (HTTP 400); Fast Mode must use the Cursor API.
enum CursorModelRewriter {
    static let host = "api-for-cursor.standardagents.ai"
    static let grok45Model = "grok-4.5"
    static let grok45FastModel = "grok-4.5-fast"

    /// Catalog id → upstream Cursor API model id (before Fast Mode).
    static let aliases: [String: String] = [
        "cursor-composer-2.5": "composer-2.5",
        "cursor-grok-4.5": grok45Model,
        "cursor-grok-4.5-fast": grok45FastModel
    ]

    /// Returns the upstream model id to send to the Cursor API.
    static func resolveUpstreamModel(_ catalogModel: String, grok45FastMode: Bool) -> String {
        let aliased = aliases[catalogModel] ?? catalogModel
        if grok45FastMode && aliased == grok45Model {
            return grok45FastModel
        }
        return aliased
    }

    /// Whether Grok OAuth Fast Mode should divert `grok-4.5` to the Cursor API.
    static func shouldDivertGrokOAuthToCursorFast(model: String, grok45FastMode: Bool) -> Bool {
        grok45FastMode && model == grok45Model
    }
}
