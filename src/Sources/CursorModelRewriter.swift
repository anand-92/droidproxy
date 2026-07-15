import Foundation

/// Resolves DroidProxy Cursor catalog model ids to upstream Cursor API model ids.
///
/// Catalog entries use a `cursor-` prefix so `ThinkingProxy.isCursorModel` routes to
/// `api-for-cursor.standardagents.ai` (not api.x.ai Grok OAuth). Upstream ids match
/// standardagents/composer-api (`grok-4.5`, `grok-4.5-fast`, `composer-2.5`, …).
///
/// Fast Mode rewrites `grok-4.5` → `grok-4.5-fast` (model-id swap, not Codex
/// `service_tier=priority`). Explicit `cursor-grok-4.5-fast` always maps to the fast id.
enum CursorModelRewriter {
    static let host = "api-for-cursor.standardagents.ai"

    /// Catalog id → upstream Cursor API model id (before Fast Mode).
    static let aliases: [String: String] = [
        "cursor-composer-2.5": "composer-2.5",
        "cursor-grok-4.5": "grok-4.5",
        "cursor-grok-4.5-fast": "grok-4.5-fast"
    ]

    /// Returns the upstream model id to send to the Cursor API.
    static func resolveUpstreamModel(_ catalogModel: String, grok45FastMode: Bool) -> String {
        let aliased = aliases[catalogModel] ?? catalogModel
        if grok45FastMode && aliased == "grok-4.5" {
            return "grok-4.5-fast"
        }
        return aliased
    }
}
