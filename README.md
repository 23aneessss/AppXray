<div align="center">

# App X-Ray

### An independent privacy & capability auditor for macOS apps — read what an app can *really* do, offline.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CI](https://github.com/23aneessss/AppXray/actions/workflows/ci.yml/badge.svg)](https://github.com/23aneessss/AppXray/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DocC](https://img.shields.io/badge/docs-DocC-informational.svg)](https://23aneessss.github.io/AppXray/documentation/appxraykit/)

</div>

> **Apple's App Store privacy "nutrition labels" are self-declared by the developer** — and most Mac apps ship outside the App Store with no label at all. So how do you actually answer: *Is this app sandboxed? Can it record my screen, mic, or keystrokes? Does it link undocumented private frameworks? Is it notarized? Does it install background helpers?*
>
> **App X-Ray reads the truth from the binary.** Point it at any `.app` and it produces a clear, plain-language inventory of what that app *can* do — straight from the bundle and its code signature, never from marketing claims. 100% offline. Nothing is uploaded, ever.

---

## What you get

```
  Spotify  1.2.x
  com.spotify.client
  x86_64, arm64

  Spotify is signed by an identified developer (team 2FNC3A47ZF). It is not
  sandboxed. It is notarized. Notable capabilities: Installs background items.
  2 high-risk flags — review the warnings.

  CAPABILITIES
    ✗ Sandboxed
    ✓ Notarized
    ✓ Hardened Runtime
    ✓ Installs background items
    …

  WARNINGS
    ● Library validation disabled
      The app can load libraries that are not signed by the same team or Apple
      — weakening a key code-integrity protection.
    ▲ Not sandboxed
      OS-level file/hardware restrictions do not apply.
```

See full sample reports in [`Examples/`](Examples/) — real output for [Calculator](Examples/Calculator.md), [Spotify](Examples/Spotify.md), and [FocusNotch](Examples/FocusNotch.md).

## Why existing tools don't cover this

| Tool | What it tells you | The gap App X-Ray fills |
|---|---|---|
| App Store privacy label | What the developer *says* | Self-declared, often incomplete, absent off-store |
| Little Snitch | Live network traffic | Nothing about capabilities/signature/entitlements |
| Antivirus | Known malware | Says nothing about a *legitimate* app's reach |
| `codesign` / `otool` | Raw, expert-only facts | No friendly explanation, no risk framing |

App X-Ray is the **friendly, independent auditor** in between: it reads the same authoritative sources as the expert tools (`Security.framework`, Mach-O) and explains them honestly.

## Install

**Homebrew** (recommended)
```bash
brew install 23aneessss/tap/appxray   # see Docs/launch.md for the tap
```

**Build from source**
```bash
git clone https://github.com/23aneessss/AppXray.git
cd AppXray
swift build -c release
cp .build/release/appxray /usr/local/bin/
```

**As a Swift package dependency**
```swift
.package(url: "https://github.com/23aneessss/AppXray.git", from: "0.1.0")
```

## Usage

```bash
appxray /Applications/Spotify.app          # clean, colour-coded terminal report
appxray /Applications/Spotify.app --json   # machine-readable JSON
appxray /Applications/Spotify.app --md     # Markdown (great for issues/PRs)
appxray SomeApp.app --out report.md        # write to a file
appxray --installed                        # summarise every app in /Applications
```

Exit codes make it useful in CI to gate a dependency:

| Code | Meaning | | Code | Meaning |
|---|---|---|---|---|
| `0` | success | | `2` | usage error |
| `1` | analysis error | | `3` | a **high-risk** flag was found |

```bash
# Fail a pipeline if a bundled .app trips a high-risk flag:
appxray ./build/MyApp.app || echo "review the report above"
```

## What it analyses

- **Identity** — name, bundle id, version, minimum macOS, URL schemes, background flags
- **Architectures** — arm64 / x86_64 / universal (flags x86-only on Apple Silicon)
- **Code signature** — Developer ID / Apple Development / ad-hoc / **unsigned**, Team ID, authority chain, **Hardened Runtime**, debuggable (`get-task-allow`)
- **Notarization & Gatekeeper** — native, reliable notarization check + Gatekeeper verdict
- **Sandbox** — the headline `app-sandbox` signal
- **Entitlements** — every one, with a friendly title, explanation, and honest risk level (sandbox escapes, library-validation, camera/mic, automation, …)
- **Privacy usage strings** — the resources it can prompt for, with the developer's stated reason
- **Linked libraries** — flags **private/undocumented frameworks**
- **Nested components** — XPC services, login items, helpers, embedded updaters (e.g. Sparkle)
- **Persistence** — bundled LaunchAgents/Daemons, login items, background-only apps
- **Network hints** — endpoint strings scraped from the binary (clearly labelled *heuristic*)
- **Capability badges** — the at-a-glance summary

## What it is — and is *not* (honest framing)

App X-Ray is built around honesty, not security theatre:

- ✅ It is an **honest capability inventory** with explained risk flags (`info` / `notable` / `high`). **You** draw the conclusions.
- ❌ It is **not** antivirus or malware detection, and never pretends to be.
- ❌ It produces **no single fake "safety score."**
- ⚖️ A sensitive entitlement means the app **can** request something — not that it **does**.
- 🌐 Core analysis is **static** (reading the bundle). Real network destinations need runtime observation; the "network hints" are heuristic string matches and are labelled as such.

## How it works

App X-Ray prefers **native Apple APIs** over shelling out:

- **`Security.framework`** (`SecStaticCode`, `SecCode`, `SecRequirement`) for the signature, entitlements dictionary, Hardened Runtime flag, and the authoritative `notarized` check.
- A **small, dependency-free Mach-O reader** for architectures and linked libraries (including big-endian universal binaries), used to detect private-framework linkage.
- `spctl` is used only for the Gatekeeper *acceptance* verdict (a documented fallback); the notarization signal itself is native and is **not** derived from `spctl` (which reflects local policy).

The reusable engine lives in **`AppXrayKit`** — fully testable, `Sendable` + `Codable` models, `os.Logger` throughout, no force-unwraps in public API, **zero third-party runtime dependencies**.

## Desktop app (GUI)

A SwiftUI app built on the same engine lives in [`App/`](App/). Browse a
searchable list of installed apps (or drag any `.app` onto the window), read a
polished report — header, colour-coded capability badges, and expandable
sections for entitlements, privacy, private frameworks, nested components, and
network hints — then export to Markdown or JSON. It is intentionally **not
sandboxed** (it must read other apps' bundles) and uses a security-scoped open
panel.

```bash
cd App
xcodegen generate          # generates App/AppXray.xcodeproj from project.yml
open AppXray.xcodeproj      # build & run in Xcode (⌘R)
```

## Project layout

```
Sources/AppXrayKit/   reusable analysis engine (the technical centrepiece)
Sources/appxray/      the CLI (zero-dependency arg parsing, colour, JSON/Markdown export)
App/                  SwiftUI GUI (xcodegen project.yml + sources)
Examples/             real sample reports for well-known apps
Tests/                unit tests over fixtures + pure logic
Docs/                 usage manual + launch guide
```

## Roadmap

- **v0.1** — `AppXrayKit` + `appxray` CLI + SwiftUI GUI (this release)
- **v0.2** — GUI polish: report diffing, deep-link to nested components
- **v0.3** — optional, clearly-labelled runtime network observation module
- Swift Package Index submission · Homebrew tap · DocC on GitHub Pages

## Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). The catalogs ([`EntitlementsCatalog`](Sources/AppXrayKit/Catalogs/EntitlementsCatalog.swift), [`PrivacyUsageCatalog`](Sources/AppXrayKit/Catalogs/PrivacyUsageCatalog.swift)) are deliberately easy to extend.

## License

[MIT](LICENSE) © 2026 23aneessss
