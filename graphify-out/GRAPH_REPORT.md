# Graph Report - /Users/dks0662779/droidproxy  (2026-04-16)

## Corpus Check
- 85 files · ~397,971 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 248 nodes · 299 edges · 48 communities detected
- Extraction: 70% EXTRACTED · 30% INFERRED · 0% AMBIGUOUS · INFERRED: 90 edges (avg confidence: 0.53)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `ThinkingProxy` - 30 edges
2. `AppDelegate` - 28 edges
3. `SettingsView` - 18 edges
4. `ServerManager` - 13 edges
5. `ThinkingProxy.processThinkingParameter` - 9 edges
6. `AuthManager` - 8 edges
7. `ServiceType` - 7 edges
8. `AuthAccount` - 6 edges
9. `ServiceAccounts` - 6 edges
10. `Opus 4.7 Max Budget branch (task_budget=128000)` - 6 edges

## Surprising Connections (you probably didn't know these)
- `Setup.tsx Factory custom models reference` --semantically_similar_to--> `SettingsView.droidProxyModels (Factory model list)`  [INFERRED] [semantically similar]
  website/src/components/Setup.tsx → src/Sources/SettingsView.swift
- `custom:droidproxy:opus-4-6 (legacy scrubbed)` --semantically_similar_to--> `custom:droidproxy:opus-4-7 Factory model`  [INFERRED] [semantically similar]
  CHANGELOG.md → SETUP.md
- `Features.tsx per-model effort controls section` --references--> `Claude Opus 4.7 model (claude-opus-4-7)`  [EXTRACTED]
  website/src/components/Features.tsx → CHANGELOG.md
- `Features.tsx per-model effort controls section` --references--> `Claude Sonnet 4.6 model (claude-sonnet-4-6)`  [EXTRACTED]
  website/src/components/Features.tsx → CHANGELOG.md
- `Setup.tsx Factory custom models reference` --references--> `custom:droidproxy:opus-4-7 Factory model`  [EXTRACTED]
  website/src/components/Setup.tsx → SETUP.md

## Hyperedges (group relationships)
- **Per-model thinking/reasoning controls pattern** — apppreferences_opus47ThinkingEffortKey, apppreferences_sonnet46ThinkingEffortKey, apppreferences_gpt53CodexReasoningEffortKey, apppreferences_gpt54ReasoningEffortKey, apppreferences_gemini31ProThinkingLevelKey, apppreferences_gemini3FlashThinkingLevelKey [INFERRED 0.90]
- **Max Budget Mode end-to-end flow** — apppreferences_claudeMaxBudgetModeKey, settingsview_MaxBudgetToggleView, thinkingproxy_opus47MaxBudget, thinkingproxy_sonnet46MaxBudget, thinkingproxy_taskBudgetsBeta, thinkingproxy_requiredClaudeBetaFlags [EXTRACTED 0.95]
- **Opus 4.6 to Opus 4.7 migration surface** — apppreferences_opus47ThinkingEffortKey, thinkingproxy_opus47MaxBudget, settingsview_legacyDroidProxyModelIds, concept_factory_model_opus_4_7, concept_factory_model_opus_4_6_legacy, concept_challenger_opus [EXTRACTED 0.95]

## Communities

### Community 0 - "ThinkingProxy Core"
Cohesion: 0.13
Nodes (2): Config, ThinkingProxy

### Community 1 - "App Lifecycle"
Cohesion: 0.1
Nodes (5): AppDelegate, NSApplicationDelegate, NSObject, NSWindowDelegate, UNUserNotificationCenterDelegate

### Community 2 - "Settings UI"
Cohesion: 0.1
Nodes (8): LogoView, AccountRowView, HazardStripesView, MaxBudgetToggleView, ServiceRow, SettingsView, Timing, View

### Community 3 - "Auth Management"
Cohesion: 0.13
Nodes (16): AuthAccount, AuthManager, ServiceAccounts, ServiceType, claude, codex, gemini, CaseIterable (+8 more)

### Community 4 - "Model Preference Keys"
Cohesion: 0.1
Nodes (23): AppPreferences.gemini31ProThinkingLevelKey, AppPreferences.gemini3FlashThinkingLevelKey, AppPreferences.gpt53CodexReasoningEffortKey, AppPreferences.gpt54ReasoningEffortKey, Claude Opus 4.7 model (claude-opus-4-7), Claude Sonnet 4.6 model (claude-sonnet-4-6), Classic extended thinking budget_tokens (Sonnet 4.6), Surgical JSON editing (preserve key order for cache_control) (+15 more)

### Community 5 - "Server Manager"
Cohesion: 0.2
Nodes (4): OutputCapture, RingBuffer, ServerManager, Timing

### Community 6 - "Website Components"
Cohesion: 0.14
Nodes (0): 

### Community 7 - "Max Budget Mode"
Cohesion: 0.15
Nodes (14): AppPreferences.claudeMaxBudgetModeKey, AppPreferences.opus47ThinkingEffortKey, AppPreferences.sonnet46ThinkingEffortKey, Adaptive thinking (thinking.type=adaptive), Max Budget Mode feature, MaxBudgetToggleView (the Big Red Button), SettingsView, SettingsView Claude model effort controls (+6 more)

### Community 8 - "Factory Model Setup"
Cohesion: 0.22
Nodes (11): Challenger droids (Opus 4.7 / GPT 5.4 / Gemini 3.1 Pro), challenger-opus droid (custom:droidproxy:opus-4-7), custom:droidproxy:opus-4-6 (legacy scrubbed), custom:droidproxy:opus-4-7 Factory model, Rationale: scrub legacy opus-4-6 entry so users don't end up with stale entries next to Opus 4.7, SettingsView.applyChallengerPlugin, SettingsView.applyFactoryCustomModels, SettingsView.challengerPluginFiles (+3 more)

### Community 9 - "Proxy Startup Flow"
Cohesion: 0.33
Nodes (6): AppDelegate, AppDelegate.pollForProxyReadiness, AppDelegate.startServer, CLIProxyAPIPlus backend (port 8318), localhost:8317 proxy endpoint, ThinkingProxy (class)

### Community 10 - "Tunnel Manager"
Cohesion: 0.5
Nodes (1): TunnelManager

### Community 11 - "Icon Catalog"
Cohesion: 0.5
Nodes (1): IconCatalog

### Community 12 - "Notification Names"
Cohesion: 1.0
Nodes (1): Notification.Name

### Community 13 - "App Preferences"
Cohesion: 1.0
Nodes (1): AppPreferences

### Community 14 - "xhigh Default Rationale"
Cohesion: 1.0
Nodes (2): AppPreferences.defaultOpus47ThinkingEffort (xhigh), Rationale: xhigh default per Anthropic's recommendation for coding/agentic workloads

### Community 15 - "Amp CLI Routing"
Cohesion: 1.0
Nodes (2): Amp CLI routing rewrites, ThinkingProxy.forwardToAmp

### Community 16 - "Sparkle: SPUInstallationType"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Sparkle: SUInstallerLauncher"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "Sparkle: SPUUserAgent"
Cohesion: 1.0
Nodes (0): 

### Community 19 - "Sparkle: SPUStandardUserDriver Private"
Cohesion: 1.0
Nodes (0): 

### Community 20 - "Sparkle: SUAppcastItem Private"
Cohesion: 1.0
Nodes (0): 

### Community 21 - "Sparkle: AppcastItemStateResolver"
Cohesion: 1.0
Nodes (0): 

### Community 22 - "Sparkle: GentleUserDriverReminders"
Cohesion: 1.0
Nodes (0): 

### Community 23 - "Sparkle: SPUDownloadData"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Sparkle: SPUUpdaterDelegate"
Cohesion: 1.0
Nodes (0): 

### Community 25 - "Sparkle: SUVersionDisplayProtocol"
Cohesion: 1.0
Nodes (0): 

### Community 26 - "Sparkle: SUAppcast"
Cohesion: 1.0
Nodes (0): 

### Community 27 - "Sparkle: SPUUpdaterSettings"
Cohesion: 1.0
Nodes (0): 

### Community 28 - "Sparkle: SUExport"
Cohesion: 1.0
Nodes (0): 

### Community 29 - "Sparkle: SPUStandardUserDriver"
Cohesion: 1.0
Nodes (0): 

### Community 30 - "Sparkle: SPUUserUpdateState"
Cohesion: 1.0
Nodes (0): 

### Community 31 - "Sparkle: SUUpdaterDelegate"
Cohesion: 1.0
Nodes (0): 

### Community 32 - "Sparkle: SPUUserDriver"
Cohesion: 1.0
Nodes (0): 

### Community 33 - "Sparkle: SUErrors"
Cohesion: 1.0
Nodes (0): 

### Community 34 - "Sparkle: SUAppcastItem"
Cohesion: 1.0
Nodes (0): 

### Community 35 - "Sparkle: StandardUserDriverDelegate"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Sparkle: StandardVersionComparator"
Cohesion: 1.0
Nodes (0): 

### Community 37 - "Sparkle: SPUUpdateCheck"
Cohesion: 1.0
Nodes (0): 

### Community 38 - "Sparkle: SPUUpdater"
Cohesion: 1.0
Nodes (0): 

### Community 39 - "Sparkle: SUUpdater"
Cohesion: 1.0
Nodes (0): 

### Community 40 - "Sparkle: StandardUpdaterController"
Cohesion: 1.0
Nodes (0): 

### Community 41 - "Sparkle: UpdatePermissionRequest"
Cohesion: 1.0
Nodes (0): 

### Community 42 - "Sparkle: VersionComparisonProtocol"
Cohesion: 1.0
Nodes (0): 

### Community 43 - "Sparkle: UpdatePermissionResponse"
Cohesion: 1.0
Nodes (0): 

### Community 44 - "Tailwind Config"
Cohesion: 1.0
Nodes (0): 

### Community 45 - "Vite Config"
Cohesion: 1.0
Nodes (0): 

### Community 46 - "PostCSS Config"
Cohesion: 1.0
Nodes (0): 

### Community 47 - "Swift Package Manifest"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **36 isolated node(s):** `Timing`, `Notification.Name`, `AppPreferences`, `Config`, `Timing` (+31 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Notification Names`** (2 nodes): `NotificationNames.swift`, `Notification.Name`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Preferences`** (2 nodes): `AppPreferences.swift`, `AppPreferences`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `xhigh Default Rationale`** (2 nodes): `AppPreferences.defaultOpus47ThinkingEffort (xhigh)`, `Rationale: xhigh default per Anthropic's recommendation for coding/agentic workloads`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Amp CLI Routing`** (2 nodes): `Amp CLI routing rewrites`, `ThinkingProxy.forwardToAmp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUInstallationType`** (1 nodes): `SPUInstallationType.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUInstallerLauncher`** (1 nodes): `SUInstallerLauncher+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUserAgent`** (1 nodes): `SPUUserAgent+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUStandardUserDriver Private`** (1 nodes): `SPUStandardUserDriver+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUAppcastItem Private`** (1 nodes): `SUAppcastItem+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: AppcastItemStateResolver`** (1 nodes): `SPUAppcastItemStateResolver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: GentleUserDriverReminders`** (1 nodes): `SPUGentleUserDriverReminders.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUDownloadData`** (1 nodes): `SPUDownloadData.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUpdaterDelegate`** (1 nodes): `SPUUpdaterDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUVersionDisplayProtocol`** (1 nodes): `SUVersionDisplayProtocol.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUAppcast`** (1 nodes): `SUAppcast.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUpdaterSettings`** (1 nodes): `SPUUpdaterSettings.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUExport`** (1 nodes): `SUExport.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUStandardUserDriver`** (1 nodes): `SPUStandardUserDriver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUserUpdateState`** (1 nodes): `SPUUserUpdateState.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUUpdaterDelegate`** (1 nodes): `SUUpdaterDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUserDriver`** (1 nodes): `SPUUserDriver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUErrors`** (1 nodes): `SUErrors.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUAppcastItem`** (1 nodes): `SUAppcastItem.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: StandardUserDriverDelegate`** (1 nodes): `SPUStandardUserDriverDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: StandardVersionComparator`** (1 nodes): `SUStandardVersionComparator.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUpdateCheck`** (1 nodes): `SPUUpdateCheck.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SPUUpdater`** (1 nodes): `SPUUpdater.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: SUUpdater`** (1 nodes): `SUUpdater.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: StandardUpdaterController`** (1 nodes): `SPUStandardUpdaterController.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: UpdatePermissionRequest`** (1 nodes): `SPUUpdatePermissionRequest.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: VersionComparisonProtocol`** (1 nodes): `SUVersionComparisonProtocol.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle: UpdatePermissionResponse`** (1 nodes): `SUUpdatePermissionResponse.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Tailwind Config`** (1 nodes): `tailwind.config.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Vite Config`** (1 nodes): `vite.config.ts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `PostCSS Config`** (1 nodes): `postcss.config.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Swift Package Manifest`** (1 nodes): `Package.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ThinkingProxy.processThinkingParameter` connect `Model Preference Keys` to `Max Budget Mode`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `ServerManager` connect `Server Manager` to `Auth Management`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `ThinkingProxy.processThinkingParameter` (e.g. with `ThinkingProxy.appendAnthropicBetaFlags` and `Rationale: force streaming for Claude to satisfy adaptive/max-mode requirements`) actually correct?**
  _`ThinkingProxy.processThinkingParameter` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Timing`, `Notification.Name`, `AppPreferences` to the rest of the system?**
  _36 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ThinkingProxy Core` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `App Lifecycle` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Settings UI` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._