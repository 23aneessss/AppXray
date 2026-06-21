# App X-Ray — Launch & Repo Polish Guide

Copy-paste-ready text for launching the project on GitHub and beyond. (Claude
can't change GitHub settings for you — these are the steps to do by hand.)

> Replace `23aneessss` with your handle and `© 2026 23aneessss` in `LICENSE`
> with your full name if you'd prefer that on the copyright line.

## Repository

- **Repo name:** `appxray` (display name: "App X-Ray")
- **About / description** (≤350 chars):

  > An independent privacy & capability auditor for macOS apps. Drop in any .app
  > and see what it can really do — sandbox, entitlements, private frameworks,
  > screen/mic/keylogging access, notarization, background helpers. 100% offline.
  > Apple's labels are self-declared; this reads the binary.

- **Topics:** `macos`, `security`, `privacy`, `swift`, `swift-package`, `cli`,
  `mach-o`, `code-signing`, `entitlements`, `app-analysis`, `reverse-engineering`,
  `developer-tools`, `notarization`, `transparency`
- **Website (About):** your DocC Pages URL (below).
- **Pin** the repo on your profile.

## DocC on GitHub Pages

1. In repo *Settings → Pages*, set **Source = GitHub Actions**.
2. Push to `main`; the `docs.yml` workflow builds DocC and deploys it.
3. The site will be at:
   `https://23aneessss.github.io/AppXray/documentation/appxraykit/`
   Put that URL in the README DocC badge and the repo's About → Website.

## First release

```bash
git tag v0.1.0
git push origin v0.1.0
```

Then draft a GitHub Release from the tag with these notes:

```markdown
## App X-Ray v0.1.0 — the engine + CLI

App X-Ray is an independent, **offline** privacy & capability auditor for macOS
apps. Point it at any `.app` and it reports what the app *can* do — sandbox,
entitlements, private frameworks, notarization, background helpers — read from
the binary and its code signature, not from self-declared privacy labels.

**Highlights**
- `AppXrayKit`: a dependency-free analysis engine (Security.framework + a native
  Mach-O reader), fully tested, `Codable` models.
- `appxray` CLI: colour terminal report, JSON/Markdown export, `--installed`
  summary, CI-friendly exit codes.
- Honest framing throughout — no fake safety score.

**Install**
`brew install 23aneessss/tap/appxray` · or build from source (`swift build -c release`).

See the README and `Examples/` for real sample reports.
```

## Homebrew tap

Create a repo named `homebrew-tap` and add `Formula/appxray.rb`:

```ruby
class Appxray < Formula
  desc "Independent, offline privacy & capability auditor for macOS apps"
  homepage "https://github.com/23aneessss/AppXray"
  url "https://github.com/23aneessss/AppXray/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"   # shasum -a 256 the downloaded tarball
  license "MIT"

  depends_on :macos
  depends_on xcode: ["15.0", :build]

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/appxray"
  end

  test do
    assert_match "App X-Ray", shell_output("#{bin}/appxray --help")
  end
end
```

Users then run: `brew install 23aneessss/tap/appxray`.

## Social preview (1280×640)

Generate the on-brand banner from code:

```bash
swift Tools/generate_banner.swift            # writes Docs/banner.png
```

Upload it in *Settings → Social preview*, and reference `Docs/banner.png` in the
README if you like.

## Swift Package Index

Submit the repo at https://swiftpackageindex.com/add-a-package — SPI builds the
DocC docs and a platform/Swift compatibility matrix automatically, which adds
credibility and a nice badge.

## Launch blurb

For r/macapps, r/swift, r/privacy, and Hacker News — lead with the angle:

> **App X-Ray — Apple's privacy labels are self-declared. Here's an independent,
> offline auditor that reads the truth from the binary.**
>
> Drop in any `.app` and see what it can actually do: sandbox status,
> entitlements (with plain-language explanations and honest risk levels), private
> framework usage, notarization, background helpers, and more. 100% offline, no
> telemetry, MIT-licensed. Built in Swift on `Security.framework` + a native
> Mach-O reader, with a reusable `AppXrayKit` library and a CLI.
