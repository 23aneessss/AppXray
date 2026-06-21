# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- GUI polish: report diffing and deep-linking into nested components.
- Optional, clearly-labelled runtime network-observation module.

## [0.1.0] — 2026-06-21

The first public release: the `AppXrayKit` analysis engine, the `appxray` CLI,
and a SwiftUI desktop app.

### Added
- **`AppXrayKit`** — a reusable, dependency-free static analysis engine with
  `Sendable` + `Codable` models and a single entry point, `AppXray.analyze(bundleAt:)`.
- **Code-signature analysis** via `Security.framework` (`SecStaticCode`): signing
  kind (Developer ID / Apple Development / Apple system / ad-hoc / unsigned), Team
  ID, authority chain, Hardened Runtime, and debuggable (`get-task-allow`) detection.
- **Reliable notarization check** using the native `SecRequirement("notarized")`
  verdict (independent of locally-overridable `spctl`).
- **Native Mach-O reader** for architectures and linked libraries, including
  big-endian universal binaries, with private-framework detection.
- **EntitlementsCatalog** and **PrivacyUsageCatalog** mapping raw keys to friendly
  titles, plain-language explanations, and honest risk levels.
- **Nested-component enumeration** (XPC services, login items, helpers, embedded
  frameworks, Sparkle updaters) and **persistence detection** (LaunchAgents/Daemons,
  login items, background-only apps).
- **Heuristic network-hint** extraction from binary strings (clearly labelled).
- **Capability badges**, derived warnings, and a one-paragraph honest summary.
- **Markdown and JSON exporters.**
- **`appxray` CLI** — colour-coded terminal report, `--json`, `--markdown`,
  `--out`, `--no-color`/`NO_COLOR`, and `--installed`; non-zero exit on a
  high-risk flag for CI gating. Zero third-party dependencies.
- **SwiftUI desktop app** (`App/`, generated with xcodegen) — searchable list of
  installed apps, drag-and-drop, a polished report view with capability badges
  and expandable sections, and Markdown/JSON export. Intentionally un-sandboxed
  with a security-scoped open panel.
- Unit tests over fixtures and pure logic; CI and DocC GitHub Actions workflows.
- Documentation: README, DocC catalog, usage manual, and launch guide.

[Unreleased]: https://github.com/23aneessss/AppXray/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/23aneessss/AppXray/releases/tag/v0.1.0
