import Combine
import Foundation

struct UsageSample {
    let model: String
    let reasoning: String
    let reasoningSource: String
    let serviceTier: String
    let status: String
    let elapsedMs: Int
    let inputTokens: Int
    let outputTokens: Int
    let reasoningTokens: Int
    let thinkingTokens: Int
    let totalTokens: Int
}

struct UsageSnapshot {
    var requestCount: Int = 0
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var reasoningTokens: Int = 0
    var thinkingTokens: Int = 0
    var totalTokens: Int = 0
    var elapsedMs: Int = 0
    var lastModel: String = "n/a"
    var lastReasoning: String = "n/a"
    var lastReasoningSource: String = "n/a"
    var lastServiceTier: String = "n/a"
    var lastStatus: String = "n/a"
    var lastElapsedMs: Int = 0
    var lastUpdatedAt: Date?

    var averageElapsedMs: Int {
        guard requestCount > 0 else { return 0 }
        return elapsedMs / requestCount
    }
}

final class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    @Published private(set) var snapshot: UsageSnapshot

    private let defaults: UserDefaults

    private enum Key {
        static let requestCount = "usage.requestCount"
        static let inputTokens = "usage.inputTokens"
        static let outputTokens = "usage.outputTokens"
        static let reasoningTokens = "usage.reasoningTokens"
        static let thinkingTokens = "usage.thinkingTokens"
        static let totalTokens = "usage.totalTokens"
        static let elapsedMs = "usage.elapsedMs"
        static let lastModel = "usage.lastModel"
        static let lastReasoning = "usage.lastReasoning"
        static let lastReasoningSource = "usage.lastReasoningSource"
        static let lastServiceTier = "usage.lastServiceTier"
        static let lastStatus = "usage.lastStatus"
        static let lastElapsedMs = "usage.lastElapsedMs"
        static let lastUpdatedAt = "usage.lastUpdatedAt"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.snapshot = Self.loadSnapshot(from: defaults)
    }

    func record(_ sample: UsageSample) {
        DispatchQueue.main.async {
            var next = self.snapshot
            next.requestCount += 1
            next.inputTokens += sample.inputTokens
            next.outputTokens += sample.outputTokens
            next.reasoningTokens += sample.reasoningTokens
            next.thinkingTokens += sample.thinkingTokens
            next.totalTokens += sample.totalTokens
            next.elapsedMs += sample.elapsedMs
            next.lastModel = sample.model
            next.lastReasoning = sample.reasoning
            next.lastReasoningSource = sample.reasoningSource
            next.lastServiceTier = sample.serviceTier
            next.lastStatus = sample.status
            next.lastElapsedMs = sample.elapsedMs
            next.lastUpdatedAt = Date()
            self.snapshot = next
            self.save(next)
        }
    }

    func reset() {
        DispatchQueue.main.async {
            let empty = UsageSnapshot()
            self.snapshot = empty
            self.save(empty)
        }
    }

    private static func loadSnapshot(from defaults: UserDefaults) -> UsageSnapshot {
        UsageSnapshot(
            requestCount: defaults.integer(forKey: Key.requestCount),
            inputTokens: defaults.integer(forKey: Key.inputTokens),
            outputTokens: defaults.integer(forKey: Key.outputTokens),
            reasoningTokens: defaults.integer(forKey: Key.reasoningTokens),
            thinkingTokens: defaults.integer(forKey: Key.thinkingTokens),
            totalTokens: defaults.integer(forKey: Key.totalTokens),
            elapsedMs: defaults.integer(forKey: Key.elapsedMs),
            lastModel: defaults.string(forKey: Key.lastModel) ?? "n/a",
            lastReasoning: defaults.string(forKey: Key.lastReasoning) ?? "n/a",
            lastReasoningSource: defaults.string(forKey: Key.lastReasoningSource) ?? "n/a",
            lastServiceTier: defaults.string(forKey: Key.lastServiceTier) ?? "n/a",
            lastStatus: defaults.string(forKey: Key.lastStatus) ?? "n/a",
            lastElapsedMs: defaults.integer(forKey: Key.lastElapsedMs),
            lastUpdatedAt: defaults.object(forKey: Key.lastUpdatedAt) as? Date
        )
    }

    private func save(_ snapshot: UsageSnapshot) {
        defaults.set(snapshot.requestCount, forKey: Key.requestCount)
        defaults.set(snapshot.inputTokens, forKey: Key.inputTokens)
        defaults.set(snapshot.outputTokens, forKey: Key.outputTokens)
        defaults.set(snapshot.reasoningTokens, forKey: Key.reasoningTokens)
        defaults.set(snapshot.thinkingTokens, forKey: Key.thinkingTokens)
        defaults.set(snapshot.totalTokens, forKey: Key.totalTokens)
        defaults.set(snapshot.elapsedMs, forKey: Key.elapsedMs)
        defaults.set(snapshot.lastModel, forKey: Key.lastModel)
        defaults.set(snapshot.lastReasoning, forKey: Key.lastReasoning)
        defaults.set(snapshot.lastReasoningSource, forKey: Key.lastReasoningSource)
        defaults.set(snapshot.lastServiceTier, forKey: Key.lastServiceTier)
        defaults.set(snapshot.lastStatus, forKey: Key.lastStatus)
        defaults.set(snapshot.lastElapsedMs, forKey: Key.lastElapsedMs)
        defaults.set(snapshot.lastUpdatedAt, forKey: Key.lastUpdatedAt)
    }
}
