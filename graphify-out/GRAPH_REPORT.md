# Graph Report - .  (2026-04-09)

## Corpus Check
- 83 files · ~388,298 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 261 nodes · 316 edges · 50 communities detected
- Extraction: 67% EXTRACTED · 33% INFERRED · 0% AMBIGUOUS · INFERRED: 104 edges (avg confidence: 0.59)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 28 edges
2. `ThinkingProxy` - 25 edges
3. `SettingsView` - 16 edges
4. `ServerManager` - 13 edges
5. `Factory Custom Models Configuration` - 9 edges
6. `ThinkingProxy Current Behavior` - 9 edges
7. `AuthManager` - 8 edges
8. `DroidProxy Application` - 8 edges
9. `ServiceType` - 7 edges
10. `Thinking Effort Configuration` - 7 edges

## Surprising Connections (you probably didn't know these)
- `One-Click OAuth Authentication` --semantically_similar_to--> `Auth and Providers System`  [INFERRED] [semantically similar]
  README.md → AGENTS.md
- `ThinkingProxy Feature` --semantically_similar_to--> `ThinkingProxy Current Behavior`  [INFERRED] [semantically similar]
  README.md → AGENTS.md
- `DroidProxy LLMs.txt Description` --conceptually_related_to--> `DroidProxy Application`  [INFERRED]
  website/public/llms.txt → README.md
- `Granular Thinking Effort Controls (v1.8.121)` --conceptually_related_to--> `Thinking Effort Configuration`  [INFERRED]
  CHANGELOG.md → SETUP.md
- `Simplified ThinkingProxy (v1.8.121)` --conceptually_related_to--> `ThinkingProxy Current Behavior`  [INFERRED]
  CHANGELOG.md → AGENTS.md

## Hyperedges (group relationships)
- **Client Request Flow Pipeline** — readme_port_8317, agents_thinkingproxy_file, agents_port_8318, readme_cliproxyapiplus [EXTRACTED 1.00]
- **Multi-Provider Thinking Parameter Injection** — agents_thinkingproxy_behavior, agents_apppreferences, setup_opus46_model, setup_sonnet46_model, setup_gpt53_codex_model, setup_gpt54_model, setup_gemini31_pro_model, setup_gemini3_flash_model [EXTRACTED 1.00]
- **Authentication and Provider Management System** — agents_authstatus, agents_auth_providers, agents_settingsview, agents_servermanager [EXTRACTED 0.90]
- **Menu Bar Icon State System** — icon_inactive_app, icon_active_app, icon_gemini_app, icon_claude_app, icon_codex_app [INFERRED 0.90]
- **AI Service Proxy Integrations** — service_claude_code, service_codex, service_gemini, settings_screenshot_ui [EXTRACTED 1.00]
- **DroidProxy Brand Identity Assets** — logo_droidproxy_app, glyph_app, icon_inactive_app, icon_active_app, factorylogo_factory_ai [INFERRED 0.80]
- **AI Service Provider Icons** — website_icon_gemini, website_icon_claude, website_icon_codex, resources_icon_gemini, resources_icon_claude, resources_icon_codex [EXTRACTED 1.00]
- **DroidProxy Brand Identity Assets** — website_logo, resources_glyph, website_icon_active, resources_icon_active, resources_icon_inactive [INFERRED 0.85]
- **Website-to-Resources Duplicated Icons** — website_icon_gemini, website_icon_claude, website_icon_codex, website_icon_active [EXTRACTED 1.00]

## Communities

### Community 0 - "App Lifecycle & Delegates"
Cohesion: 0.1
Nodes (5): AppDelegate, NSApplicationDelegate, NSObject, NSWindowDelegate, UNUserNotificationCenterDelegate

### Community 1 - "Architecture Documentation"
Cohesion: 0.09
Nodes (28): Amp Request Routing, AppDelegate.swift, Architecture Overview, Auth and Providers System, AuthStatus.swift / AuthManager, config.yaml (CLIProxyAPIPlus Config), Localhost Port 8318 (CLIProxyAPIPlus Backend), Rationale: Backend Localhost-Only Binding (+20 more)

### Community 2 - "ThinkingProxy Core"
Cohesion: 0.16
Nodes (2): Config, ThinkingProxy

### Community 3 - "Auth Management"
Cohesion: 0.13
Nodes (16): AuthAccount, AuthManager, ServiceAccounts, ServiceType, claude, codex, gemini, CaseIterable (+8 more)

### Community 4 - "Settings UI"
Cohesion: 0.12
Nodes (6): LogoView, AccountRowView, ServiceRow, SettingsView, Timing, View

### Community 5 - "Server Management"
Cohesion: 0.2
Nodes (4): OutputCapture, RingBuffer, ServerManager, Timing

### Community 6 - "Provider Configuration"
Cohesion: 0.18
Nodes (18): AppPreferences.swift, ThinkingProxy Current Behavior, Granular Thinking Effort Controls (v1.8.121), Simplified ThinkingProxy (v1.8.121), Claude Provider (Anthropic), Codex Provider (OpenAI), Gemini Provider (Google), Localhost Port 8317 (User-Facing Proxy) (+10 more)

### Community 7 - "Brand & Icon Assets"
Cohesion: 0.17
Nodes (15): DroidProxy Brand Identity, Factory.ai Brand / Organization, Factory.ai Logo (SVG), DroidProxy Glyph Icon, DroidProxy Active Menu Bar Icon, DroidProxy Claude Status Icon, DroidProxy Codex Status Icon, DroidProxy Gemini Status Icon (+7 more)

### Community 8 - "Website Components"
Cohesion: 0.14
Nodes (0): 

### Community 9 - "Resource Assets"
Cohesion: 0.15
Nodes (13): DroidProxy Glyph Icon, Active Status Icon (App Resources), Claude Service Icon (App Resources), Codex Service Icon (App Resources), Gemini Service Icon (App Resources), Inactive Status Icon (App Resources), Factory.ai Logo SVG, Active Status Icon (Website) (+5 more)

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

### Community 14 - "Changelog Metadata"
Cohesion: 1.0
Nodes (2): DroidProxy Changelog, Semantic Versioning

### Community 15 - "SEO & Robots Config"
Cohesion: 1.0
Nodes (2): Robots.txt Configuration, droidproxy.app Sitemap

### Community 16 - "Sparkle Install Types"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Sparkle Installer Launcher"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "Sparkle User Agent"
Cohesion: 1.0
Nodes (0): 

### Community 19 - "Sparkle User Driver"
Cohesion: 1.0
Nodes (0): 

### Community 20 - "Sparkle Appcast Item"
Cohesion: 1.0
Nodes (0): 

### Community 21 - "Sparkle State Resolver"
Cohesion: 1.0
Nodes (0): 

### Community 22 - "Sparkle Reminders"
Cohesion: 1.0
Nodes (0): 

### Community 23 - "Sparkle Download Data"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Sparkle Updater Delegate"
Cohesion: 1.0
Nodes (0): 

### Community 25 - "Sparkle Version Display"
Cohesion: 1.0
Nodes (0): 

### Community 26 - "Sparkle Appcast"
Cohesion: 1.0
Nodes (0): 

### Community 27 - "Sparkle Updater Settings"
Cohesion: 1.0
Nodes (0): 

### Community 28 - "Sparkle Exports"
Cohesion: 1.0
Nodes (0): 

### Community 29 - "Sparkle Standard Driver"
Cohesion: 1.0
Nodes (0): 

### Community 30 - "Sparkle User Update State"
Cohesion: 1.0
Nodes (0): 

### Community 31 - "Sparkle Update Delegate"
Cohesion: 1.0
Nodes (0): 

### Community 32 - "Sparkle User Driver Protocol"
Cohesion: 1.0
Nodes (0): 

### Community 33 - "Sparkle Errors"
Cohesion: 1.0
Nodes (0): 

### Community 34 - "Sparkle Appcast Item Type"
Cohesion: 1.0
Nodes (0): 

### Community 35 - "Sparkle Driver Delegate"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Sparkle Version Comparator"
Cohesion: 1.0
Nodes (0): 

### Community 37 - "Sparkle Update Check"
Cohesion: 1.0
Nodes (0): 

### Community 38 - "Sparkle Updater Core"
Cohesion: 1.0
Nodes (0): 

### Community 39 - "Sparkle Updater Interface"
Cohesion: 1.0
Nodes (0): 

### Community 40 - "Sparkle Controller"
Cohesion: 1.0
Nodes (0): 

### Community 41 - "Sparkle Permission Request"
Cohesion: 1.0
Nodes (0): 

### Community 42 - "Sparkle Version Comparison"
Cohesion: 1.0
Nodes (0): 

### Community 43 - "Sparkle Permission Response"
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

### Community 47 - "Package Config"
Cohesion: 1.0
Nodes (0): 

### Community 48 - "Gemini Support Milestone"
Cohesion: 1.0
Nodes (1): Gemini Provider Support (Unreleased)

### Community 49 - "Codex Support Milestone"
Cohesion: 1.0
Nodes (1): Codex Provider Support (v1.8.121)

## Knowledge Gaps
- **43 isolated node(s):** `Timing`, `Notification.Name`, `AppPreferences`, `Config`, `Timing` (+38 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Notification Names`** (2 nodes): `NotificationNames.swift`, `Notification.Name`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Preferences`** (2 nodes): `AppPreferences.swift`, `AppPreferences`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Changelog Metadata`** (2 nodes): `DroidProxy Changelog`, `Semantic Versioning`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `SEO & Robots Config`** (2 nodes): `Robots.txt Configuration`, `droidproxy.app Sitemap`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Install Types`** (1 nodes): `SPUInstallationType.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Installer Launcher`** (1 nodes): `SUInstallerLauncher+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle User Agent`** (1 nodes): `SPUUserAgent+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle User Driver`** (1 nodes): `SPUStandardUserDriver+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Appcast Item`** (1 nodes): `SUAppcastItem+Private.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle State Resolver`** (1 nodes): `SPUAppcastItemStateResolver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Reminders`** (1 nodes): `SPUGentleUserDriverReminders.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Download Data`** (1 nodes): `SPUDownloadData.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Updater Delegate`** (1 nodes): `SPUUpdaterDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Version Display`** (1 nodes): `SUVersionDisplayProtocol.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Appcast`** (1 nodes): `SUAppcast.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Updater Settings`** (1 nodes): `SPUUpdaterSettings.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Exports`** (1 nodes): `SUExport.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Standard Driver`** (1 nodes): `SPUStandardUserDriver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle User Update State`** (1 nodes): `SPUUserUpdateState.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Update Delegate`** (1 nodes): `SUUpdaterDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle User Driver Protocol`** (1 nodes): `SPUUserDriver.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Errors`** (1 nodes): `SUErrors.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Appcast Item Type`** (1 nodes): `SUAppcastItem.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Driver Delegate`** (1 nodes): `SPUStandardUserDriverDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Version Comparator`** (1 nodes): `SUStandardVersionComparator.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Update Check`** (1 nodes): `SPUUpdateCheck.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Updater Core`** (1 nodes): `SPUUpdater.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Updater Interface`** (1 nodes): `SUUpdater.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Controller`** (1 nodes): `SPUStandardUpdaterController.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Permission Request`** (1 nodes): `SPUUpdatePermissionRequest.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Version Comparison`** (1 nodes): `SUVersionComparisonProtocol.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sparkle Permission Response`** (1 nodes): `SUUpdatePermissionResponse.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Tailwind Config`** (1 nodes): `tailwind.config.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Vite Config`** (1 nodes): `vite.config.ts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `PostCSS Config`** (1 nodes): `postcss.config.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Package Config`** (1 nodes): `Package.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Gemini Support Milestone`** (1 nodes): `Gemini Provider Support (Unreleased)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Codex Support Milestone`** (1 nodes): `Codex Provider Support (v1.8.121)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DroidProxy Application` connect `Architecture Documentation` to `Provider Configuration`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `ServerManager` connect `Server Management` to `Auth Management`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `Timing`, `Notification.Name`, `AppPreferences` to the rest of the system?**
  _43 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Lifecycle & Delegates` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Architecture Documentation` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._
- **Should `Auth Management` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Settings UI` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._