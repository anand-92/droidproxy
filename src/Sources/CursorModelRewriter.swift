import Foundation

/// Resolves Cursor catalog ids and Grok Fast Mode rewrites for the hosted Cursor API.
///
/// - Catalog entries use a `cursor-` prefix so ThinkingProxy routes to
///   `api-for-cursor.standardagents.ai` (not api.x.ai Grok OAuth).
/// - Upstream ids match standardagents/composer-api (`grok-4.6`, `grok-4.6-fast`, …).
/// - Fast Mode rewrites `grok-4.6` → `grok-4.6-fast` (model-id swap). api.x.ai does
///   **not** expose `grok-4.6-fast`; Fast Mode must use the Cursor API.
enum CursorModelRewriter {
    static let host = "api-for-cursor.standardagents.ai"
    static let grok46Model = "grok-4.6"
    static let grok46FastModel = "grok-4.6-fast"

    /// Catalog id → upstream Cursor API model id (before Fast Mode).
    static let aliases: [String: String] = [
        "cursor-composer-2.5": "composer-2.5",
        "cursor-grok-4.6": grok46Model,
        "cursor-grok-4.6-fast": grok46FastModel
    ]

    /// Returns the upstream model id to send to the Cursor API.
    static func resolveUpstreamModel(_ catalogModel: String, grok46FastMode: Bool) -> String {
        let aliased = aliases[catalogModel] ?? catalogModel
        if grok46FastMode && aliased == grok46Model {
            return grok46FastModel
        }
        return aliased
    }

    /// Whether Grok OAuth Fast Mode should divert `grok-4.6` to the Cursor API.
    static func shouldDivertGrokOAuthToCursorFast(model: String, grok46FastMode: Bool) -> Bool {
        grok46FastMode && model == grok46Model
    }
}
