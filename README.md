# DroidProxy

<p align="center">
  <img src="logo.png" alt="DroidProxy" width="128">
</p>

A native macOS menu bar app that proxies Claude Code authentication for use with AI coding tools like [<img src="factory-logo.svg" alt="Factory.ai" height="16">](https://app.factory.ai) Droids. Built on [CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus).

## Download

Grab the latest release from [Releases](https://github.com/anand-92/droidproxy/releases/latest):

- **DroidProxy-arm64.dmg** -- Apple Silicon (M1/M2/M3/M4)
- **DroidProxy-arm64.zip** -- ZIP alternative

All releases are code-signed and notarized by Apple. Existing installs auto-update via Sparkle.

## Features

- **One-click Claude Code auth** -- OAuth login from the menu bar, credential monitoring, auto-refresh
- **Extended thinking proxy** -- Injects `thinking` parameters into Anthropic API calls so you can use `-thinking-N` model suffixes (e.g. `claude-opus-4-6-thinking-128000`)
- **Opus 4.6 / Sonnet 4.6 support** -- Adaptive thinking with configurable effort (`auto` or `max`), 128K output cap, interleaved thinking
- **Sparkle auto-updates** -- Checks daily, installs in the background
- **Factory integration** -- Drop-in custom model config for Factory Droids

## Setup

See [SETUP.md](SETUP.md) for authentication and Factory configuration instructions.

## Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4)

## Build from source

```bash
# Debug build
make build

# Release build + signed .app bundle
./create-app-bundle.sh
```

## Project Structure

```
src/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # Menu bar & window management
│   ├── ServerManager.swift     # Server process control & auth
│   ├── SettingsView.swift      # Main UI
│   ├── AuthStatus.swift        # Auth file monitoring
│   ├── ThinkingProxy.swift     # Thinking parameter injection proxy
│   ├── TunnelManager.swift     # Network tunnel management
│   ├── IconCatalog.swift       # Icon loading & caching
│   ├── NotificationNames.swift # Notification constants
│   └── Resources/
│       ├── cli-proxy-api-plus  # CLIProxyAPIPlus binary
│       ├── config.yaml         # Server config
│       ├── AppIcon.icns        # App icon
│       ├── icon-active.png     # Menu bar icon (active)
│       ├── icon-inactive.png   # Menu bar icon (inactive)
│       └── icon-claude.png     # Claude service icon
├── Package.swift
└── Info.plist
```

## License

MIT
