import Foundation

enum AppPreferences {
    static let opus46ThinkingEffortKey = "opus46ThinkingEffort"
    static let sonnet46ThinkingEffortKey = "sonnet46ThinkingEffort"
    static let gpt53CodexReasoningEffortKey = "gpt53CodexReasoningEffort"
    static let gpt54ReasoningEffortKey = "gpt54ReasoningEffort"
    static let gpt53CodexFastModeKey = "gpt53CodexFastMode"
    static let gpt54FastModeKey = "gpt54FastMode"
    static let gemini31ProThinkingLevelKey = "gemini31ProThinkingLevel"
    static let gemini3FlashThinkingLevelKey = "gemini3FlashThinkingLevel"
    static let claudeMaxBudgetModeKey = "claudeMaxBudgetMode"
    static let allowRemoteKey = "allowRemote"
    static let secretKeyKey = "secretKey"
    static let defaultOpus46ThinkingEffort = "max"
    static let defaultSonnet46ThinkingEffort = "high"
    static let defaultGpt53CodexReasoningEffort = "high"
    static let defaultGpt54ReasoningEffort = "high"
    static let defaultGpt53CodexFastMode = false
    static let defaultGpt54FastMode = false
    static let defaultGemini31ProThinkingLevel = "high"
    static let defaultGemini3FlashThinkingLevel = "high"
    static let defaultClaudeMaxBudgetMode = false
    static let defaultAllowRemote = false
    static let defaultSecretKey = ""

    static var opus46ThinkingEffort: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: opus46ThinkingEffortKey) != nil else {
            return defaultOpus46ThinkingEffort
        }
        return defaults.string(forKey: opus46ThinkingEffortKey) ?? defaultOpus46ThinkingEffort
    }

    static var sonnet46ThinkingEffort: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: sonnet46ThinkingEffortKey) != nil else {
            return defaultSonnet46ThinkingEffort
        }
        return defaults.string(forKey: sonnet46ThinkingEffortKey) ?? defaultSonnet46ThinkingEffort
    }

    static var gpt53CodexReasoningEffort: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: gpt53CodexReasoningEffortKey) != nil else {
            return defaultGpt53CodexReasoningEffort
        }
        return defaults.string(forKey: gpt53CodexReasoningEffortKey) ?? defaultGpt53CodexReasoningEffort
    }

    static var gpt54ReasoningEffort: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: gpt54ReasoningEffortKey) != nil else {
            return defaultGpt54ReasoningEffort
        }
        return defaults.string(forKey: gpt54ReasoningEffortKey) ?? defaultGpt54ReasoningEffort
    }

    static var gpt53CodexFastMode: Bool {
        UserDefaults.standard.bool(forKey: gpt53CodexFastModeKey)
    }

    static var gpt54FastMode: Bool {
        UserDefaults.standard.bool(forKey: gpt54FastModeKey)
    }

    static var gemini31ProThinkingLevel: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: gemini31ProThinkingLevelKey) != nil else {
            return defaultGemini31ProThinkingLevel
        }
        return defaults.string(forKey: gemini31ProThinkingLevelKey) ?? defaultGemini31ProThinkingLevel
    }

    static var gemini3FlashThinkingLevel: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: gemini3FlashThinkingLevelKey) != nil else {
            return defaultGemini3FlashThinkingLevel
        }
        return defaults.string(forKey: gemini3FlashThinkingLevelKey) ?? defaultGemini3FlashThinkingLevel
    }

    static var claudeMaxBudgetMode: Bool {
        UserDefaults.standard.bool(forKey: claudeMaxBudgetModeKey)
    }

    static var allowRemote: Bool {
        UserDefaults.standard.bool(forKey: allowRemoteKey)
    }

    static var secretKey: String {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: secretKeyKey) != nil else {
            return defaultSecretKey
        }
        return defaults.string(forKey: secretKeyKey) ?? defaultSecretKey
    }
}
