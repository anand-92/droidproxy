import Foundation

enum DroidProxyModelKind {
    case claudeAdaptive
    case codex
    case kimi
    case antigravity
    case cursor
    case junie
    case grok
}

struct DroidProxyThinkingLevel: Equatable {
    let value: String
    let displayName: String
}

struct DroidProxyModelDefinition: Equatable {
    let baseModel: String
    let idSlug: String
    let displayName: String
    let maxOutputTokens: Int
    let provider: String
    let providerKey: String
    let baseURL: String
    let kind: DroidProxyModelKind
    let levels: [DroidProxyThinkingLevel]
    let defaultLevelValue: String

    init(baseModel: String,
         idSlug: String,
         displayName: String,
         maxOutputTokens: Int,
         provider: String,
         providerKey: String,
         baseURL: String,
         kind: DroidProxyModelKind,
         levels: [DroidProxyThinkingLevel],
         defaultLevelValue: String) {
        self.baseModel = baseModel
        self.idSlug = idSlug
        self.displayName = displayName
        self.maxOutputTokens = maxOutputTokens
        self.provider = provider
        self.providerKey = providerKey
        self.baseURL = baseURL
        self.kind = kind
        self.levels = levels
        self.defaultLevelValue = defaultLevelValue
    }

    var simpleID: String {
        "custom:droidproxy:\(idSlug)"
    }

    private var settingsDisplayName: String {
        switch kind {
        case .antigravity:
            return "Antigravity: \(displayName)"
        default:
            return displayName
        }
    }

    /// Settings entry for Factory's custom model schema.
    ///
    /// Keep all reasoning metadata explicit so Droid/Factory does not need to
    /// infer supported effort levels from built-in model defaults.
    var settingsEntry: [String: Any] {
        var entry: [String: Any] = [
            "model": baseModel,
            "id": simpleID,
            "baseUrl": baseURL,
            "apiKey": "dummy-not-used",
            "displayName": "DroidProxy: \(settingsDisplayName)",
            "maxOutputTokens": maxOutputTokens,
            "noImageSupport": false,
            "provider": provider
        ]
        guard !levels.isEmpty else { return entry }
        entry["enableThinking"] = true
        entry["supportedReasoningEfforts"] = levels.map(\.value)
        entry["defaultReasoningEffort"] = defaultLevelValue
        entry["reasoningEffort"] = levels.count == 1 ? levels[0].value : defaultLevelValue
        return entry
    }
}

enum DroidProxyModelCatalog {
    private static let none = DroidProxyThinkingLevel(value: "none", displayName: "None")
    private static let dynamic = DroidProxyThinkingLevel(value: "dynamic", displayName: "Dynamic")
    private static let low = DroidProxyThinkingLevel(value: "low", displayName: "Low")
    private static let medium = DroidProxyThinkingLevel(value: "medium", displayName: "Medium")
    private static let high = DroidProxyThinkingLevel(value: "high", displayName: "High")
    private static let xhigh = DroidProxyThinkingLevel(value: "xhigh", displayName: "xHigh")
    private static let max = DroidProxyThinkingLevel(value: "max", displayName: "Max")

    private static let claudeAdvancedLevels = [low, medium, high, xhigh, max]
    private static let codexLevels = [low, medium, high, xhigh]
    private static let gpt56Levels = [none, low, medium, high, xhigh, max]
    private static let gpt56SolLevels = [dynamic, low, medium, high, xhigh, max]

    private static func antigravityModel(
        baseModel: String,
        idSlug: String,
        displayName: String,
        maxOutputTokens: Int = 65536,
        levels: [DroidProxyThinkingLevel] = [high],
        defaultLevelValue: String = "high"
    ) -> DroidProxyModelDefinition {
        DroidProxyModelDefinition(
            baseModel: baseModel,
            idSlug: idSlug,
            displayName: displayName,
            maxOutputTokens: maxOutputTokens,
            provider: "openai",
            providerKey: "antigravity",
            baseURL: "http://localhost:8317/v1",
            kind: .antigravity,
            levels: levels,
            defaultLevelValue: defaultLevelValue
        )
    }

    static var definitions: [DroidProxyModelDefinition] {
        var list = [
            DroidProxyModelDefinition(
                baseModel: "claude-fable-5",
                idSlug: "fable-5",
                displayName: "Fable 5",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "claude",
                baseURL: "http://localhost:8317",
                kind: .claudeAdaptive,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),
            DroidProxyModelDefinition(
                baseModel: "claude-opus-4-8",
                idSlug: "opus-4-8",
                displayName: "Opus 4.8",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "claude",
                baseURL: "http://localhost:8317",
                kind: .claudeAdaptive,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),
            DroidProxyModelDefinition(
                baseModel: "claude-sonnet-5",
                idSlug: "sonnet-5",
                displayName: "Sonnet 5",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "claude",
                baseURL: "http://localhost:8317",
                kind: .claudeAdaptive,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),

            DroidProxyModelDefinition(
                baseModel: "gpt-5.4",
                idSlug: "gpt-5.4",
                displayName: "GPT 5.4",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "codex",
                baseURL: "http://localhost:8317/v1",
                kind: .codex,
                levels: codexLevels,
                defaultLevelValue: "high"
            ),
            DroidProxyModelDefinition(
                baseModel: "gpt-5.5",
                idSlug: "gpt-5.5",
                displayName: "GPT 5.5",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "codex",
                baseURL: "http://localhost:8317/v1",
                kind: .codex,
                levels: codexLevels,
                defaultLevelValue: "high"
            ),
            DroidProxyModelDefinition(
                baseModel: "gpt-5.6-terra",
                idSlug: "gpt-5.6-terra",
                displayName: "GPT 5.6 Terra",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "codex",
                baseURL: "http://localhost:8317/v1",
                kind: .codex,
                levels: gpt56Levels,
                defaultLevelValue: "medium"
            ),
            DroidProxyModelDefinition(
                baseModel: "gpt-5.6-sol",
                idSlug: "gpt-5.6-sol",
                displayName: "GPT 5.6 Sol",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "codex",
                baseURL: "http://localhost:8317/v1",
                kind: .codex,
                levels: gpt56SolLevels,
                defaultLevelValue: "medium"
            ),
            // Antigravity subscription models routed through the antigravity executor via
            // OpenAI-compatible chat-completions. provider="openai" + baseURL ending in
            // /v1 makes Factory's Droid CLI send POST /v1/chat/completions, which the
            // antigravity executor handles natively using the antigravity auth file.
            antigravityModel(
                baseModel: "gemini-pro-agent",
                idSlug: "antigravity-gemini-3.1-pro",
                displayName: "Gemini 3.1 Pro (High)"
            ),
            antigravityModel(
                baseModel: "gemini-3.1-pro-low",
                idSlug: "gemini-3.1-pro-low",
                displayName: "Gemini 3.1 Pro (Low)",
                levels: [low],
                defaultLevelValue: "low"
            ),
            antigravityModel(
                baseModel: "gemini-3-flash",
                idSlug: "antigravity-gemini-3-flash",
                displayName: "Gemini 3 Flash"
            ),
            antigravityModel(
                baseModel: "gemini-3-flash-agent",
                idSlug: "gemini-3.5-flash",
                displayName: "Gemini 3.5 Flash",
                levels: [medium, high],
                defaultLevelValue: "high"
            ),
            antigravityModel(
                baseModel: "gemini-3.5-flash-low",
                idSlug: "gemini-3.5-flash-low",
                displayName: "Gemini 3.5 Flash (Low)",
                levels: [low],
                defaultLevelValue: "low"
            ),
            antigravityModel(
                baseModel: "gemini-3.1-flash-lite",
                idSlug: "gemini-3.1-flash-lite",
                displayName: "Gemini 3.1 Flash Lite"
            ),
            antigravityModel(
                baseModel: "ag-c46s-thinking",
                idSlug: "ag-c46s-thinking",
                displayName: "Claude Sonnet 4.6 (Thinking)",
                maxOutputTokens: 64000
            ),
            antigravityModel(
                baseModel: "ag-c46o-thinking",
                idSlug: "ag-c46o-thinking",
                displayName: "Claude Opus 4.6 (Thinking)",
                maxOutputTokens: 64000
            ),
            antigravityModel(
                baseModel: "gpt-oss-120b-medium",
                idSlug: "gpt-oss-120b-medium",
                displayName: "GPT-OSS 120B (Medium)",
                maxOutputTokens: 32768,
                levels: [medium],
                defaultLevelValue: "medium"
            ),
            DroidProxyModelDefinition(
                baseModel: "kimi-k2.6",
                idSlug: "kimi-k2.6",
                displayName: "Kimi K2.6",
                maxOutputTokens: 262144,
                provider: "openai",
                providerKey: "kimi",
                baseURL: "http://localhost:8317/v1",
                kind: .kimi,
                levels: [high],
                defaultLevelValue: "high"
            ),

            // Junie (JetBrains AI) subscription models. Routed through the antigravity-style
            // Junie executor in ThinkingProxy, which strips the `junie-` prefix and forwards
            // to the JetBrains Grazie backend over TLS using the key in junie.json. The
            // `junie-` prefix keeps these distinct from the OAuth Claude entries above.
            DroidProxyModelDefinition(
                baseModel: "junie-claude-sonnet-5",
                idSlug: "junie-claude-sonnet-5",
                displayName: "Junie Sonnet 5",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "junie",
                baseURL: "http://localhost:8317",
                kind: .junie,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),
            DroidProxyModelDefinition(
                baseModel: "junie-claude-opus-4-8",
                idSlug: "junie-claude-opus-4-8",
                displayName: "Junie Opus 4.8",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "junie",
                baseURL: "http://localhost:8317",
                kind: .junie,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),
            DroidProxyModelDefinition(
                baseModel: "junie-claude-fable-5",
                idSlug: "junie-claude-fable-5",
                displayName: "Junie Fable 5",
                maxOutputTokens: 128000,
                provider: "anthropic",
                providerKey: "junie",
                baseURL: "http://localhost:8317",
                kind: .junie,
                levels: claudeAdvancedLevels,
                defaultLevelValue: "xhigh"
            ),

            // Grok OAuth (SuperGrok / X Premium+) via api.x.ai.
            // provider="openai" + /v1 → Responses API; ThinkingProxy attaches the bearer.
            DroidProxyModelDefinition(
                baseModel: "grok-4.5",
                idSlug: "grok-4.5",
                displayName: "Grok 4.5",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "grok",
                baseURL: "http://localhost:8317/v1",
                kind: .grok,
                levels: codexLevels,
                defaultLevelValue: "high"
            ),
            DroidProxyModelDefinition(
                baseModel: "grok-4.3",
                idSlug: "grok-4.3",
                displayName: "Grok 4.3",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "grok",
                baseURL: "http://localhost:8317/v1",
                kind: .grok,
                levels: codexLevels,
                defaultLevelValue: "high"
            ),
            DroidProxyModelDefinition(
                baseModel: "grok-build-0.1",
                idSlug: "grok-build-0.1",
                displayName: "Grok Build",
                maxOutputTokens: 128000,
                provider: "openai",
                providerKey: "grok",
                baseURL: "http://localhost:8317/v1",
                kind: .grok,
                levels: codexLevels,
                defaultLevelValue: "high"
            )
        ]

        if BETA_FLAG {
            list.append(contentsOf: [
                DroidProxyModelDefinition(
                    baseModel: "cursor-composer-2.5",
                    idSlug: "cursor-composer-2.5",
                    displayName: "Cursor Composer 2.5",
                    maxOutputTokens: 128000,
                    provider: "generic-chat-completion-api",
                    providerKey: "cursor",
                    baseURL: "http://localhost:8317/v1",
                    kind: .cursor,
                    levels: [high],
                    defaultLevelValue: "high"
                ),
                DroidProxyModelDefinition(
                    baseModel: "cursor-small",
                    idSlug: "cursor-small",
                    displayName: "Cursor Small",
                    maxOutputTokens: 64000,
                    provider: "generic-chat-completion-api",
                    providerKey: "cursor",
                    baseURL: "http://localhost:8317/v1",
                    kind: .cursor,
                    levels: [high],
                    defaultLevelValue: "high"
                )
            ])
        }

        return list
    }

    static func settingsModels(providerIsEnabled: (String) -> Bool = { _ in true }) -> [[String: Any]] {
        definitions.compactMap { definition in
            guard providerIsEnabled(definition.providerKey) else { return nil }
            return definition.settingsEntry
        }
    }

    static var allSettingsIDs: Set<String> {
        Set(definitions.map(\.simpleID))
    }
}
