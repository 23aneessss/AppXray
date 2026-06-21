# Contributing to App X-Ray

Thanks for your interest! App X-Ray aims to be a *trustworthy* tool, so
contributions are held to one overriding principle: **honesty over hype.** No
fake safety scores, no fear-mongering, and every claim must be backed by what
the binary actually says.

## Getting started

```bash
git clone https://github.com/23aneessss/AppXray.git
cd AppXray
swift build
swift test
.build/debug/appxray /System/Applications/Calculator.app
```

Requires macOS 13+ and a recent Swift toolchain (Swift 6 / Xcode 16+).

## Ways to contribute

- **Extend the catalogs.** Adding an entitlement or privacy-usage key is the
  easiest, highest-value contribution. Edit
  [`EntitlementsCatalog`](Sources/AppXrayKit/Catalogs/EntitlementsCatalog.swift) or
  [`PrivacyUsageCatalog`](Sources/AppXrayKit/Catalogs/PrivacyUsageCatalog.swift),
  give a friendly title, a plain-language explanation, and a justified risk level.
- **Improve detection** in the inspectors (e.g. more nested-component kinds).
- **The GUI** (Phase 2) and docs/examples.

## Guidelines

- **Prefer native APIs** (`Security.framework`, the Mach-O reader) over shelling
  out. Document any shell fallback and why it's needed.
- **No third-party runtime dependencies** in `AppXrayKit` or the CLI.
- **No `print` in library code** — use `os.Logger`. **No force-unwraps** in
  public API; use typed errors. Public model types stay `Sendable` + `Codable`.
- **Keep parsing pure and testable.** New logic should come with a unit test;
  prefer testing pure functions over end-to-end where possible.
- **Risk levels must be defensible.** `high` is for genuine red flags (unsigned
  code, sandbox escapes, library-validation disabled), not for anything merely
  uncommon. When in doubt, `notable`.

## Submitting changes

1. Fork and branch from `main`.
2. Run `swift build` **and** `swift test` — both must pass.
3. Keep commits focused and write a clear message.
4. Open a PR describing the change and, for catalog/detection changes, the app(s)
   you verified against.

By contributing you agree your work is licensed under the project's
[MIT License](LICENSE).
