# App X-Ray — User Manual

App X-Ray tells you what a macOS app *can* do, read directly from its bundle and
code signature. This manual walks through installing it, running it, reading
each section of a report, and — importantly — interpreting the results honestly.

---

## 1. Install

The quickest path from source:

```bash
git clone https://github.com/23aneessss/AppXray.git
cd AppXray
swift build -c release
cp .build/release/appxray /usr/local/bin/        # optional: put it on your PATH
```

Or, once the Homebrew tap is published (see [launch.md](launch.md)):

```bash
brew install 23aneessss/tap/appxray
```

## 2. Run it on an app

```bash
appxray /Applications/Spotify.app
```

By default you get a colour-coded terminal report. Other output modes:

| Command | Output |
|---|---|
| `appxray App.app` | Coloured terminal report |
| `appxray App.app --json` | JSON (for scripts/pipelines) |
| `appxray App.app --markdown` | Markdown (for issues, PRs, docs) |
| `appxray App.app --out report.md` | Write to a file |
| `appxray App.app --no-color` | Plain text (also honours `NO_COLOR`) |
| `appxray --installed` | One-line summary of every app in `/Applications` |

### Full Disk Access

Reading some bundles (and their signatures) may require **Full Disk Access**. If
analysis fails with a read error, grant your terminal Full Disk Access in
*System Settings → Privacy & Security → Full Disk Access*, then try again.

## 3. Read each section

**Summary** — one honest paragraph: who signed it, whether it's sandboxed and
notarized, the notable capabilities, and how many high-risk flags were raised.

**Capabilities** — at-a-glance badges (Sandboxed, Notarized, Hardened Runtime,
Can record screen, Can access camera/mic, Can control other apps, Links private
frameworks, Installs background items, Universal binary).

**Code signature** — the signing kind, Team ID, Hardened Runtime, sandbox and
notarization status, and the leaf authority. This is the trust backbone.

**Warnings** — the most important signals distilled into plain language, ordered
by severity.

**Entitlements** — every entitlement the signature claims, each with a friendly
title, the rendered value, a risk level, and an explanation. Unknown entitlements
are still listed (as `info`) for transparency.

**Privacy resources it can request** — the `NS*UsageDescription` strings, i.e.
the permission prompts the app *can* show, with the developer's stated reason.

**Private/undocumented frameworks**, **Nested components**, **URL schemes**,
**Associated domains**, **Network hints** — the remaining surface area.

## 4. Export and share

```bash
appxray /Applications/Spotify.app --markdown --out Spotify-audit.md
appxray /Applications/Spotify.app --json     --out Spotify-audit.json
```

Markdown is ideal for attaching to a review or issue; JSON is stable
(sorted keys) and good for diffing two versions of an app over time.

## 5. Interpret risk levels — honestly

App X-Ray uses three levels, and **you** draw the conclusions:

- **`info`** — neutral fact. Not a concern on its own.
- **`notable`** — worth understanding in context (a development build, a
  sensitive entitlement, an unnotarized identified developer, a sensitive
  privacy resource).
- **`high`** — a strong signal worth scrutiny: **unsigned** code, sandbox
  **temporary exceptions** (sanctioned escapes), **library validation disabled**,
  broad **all-files** access.

Crucial framing:

- A capability badge being **on** means the app *can* do something — **not** that
  it *does*. "Can access camera" means it declared the ability to request it.
- **Apple system apps** are signed by `Software Signing` and read as *not
  notarized* — that is expected and **not** a red flag.
- **Network hints** are heuristic strings pulled from the binary. They are
  **not proof** of any connection — only a hint at possible endpoints.

## 6. Limitations

- **Static only.** App X-Ray reads the bundle on disk. It does not run the app,
  observe live traffic, or inspect runtime behaviour. Real network destinations
  require runtime observation (a planned, clearly-labelled optional module).
- **Not malware detection.** A clean report is not a clean bill of health, and a
  high-risk flag is not proof of wrongdoing — many legitimate apps (browsers,
  runtimes) carry relaxations like JIT or library-validation for good reasons.
- **TCC permissions** (Screen Recording, Accessibility, Input Monitoring) are
  granted at runtime and are inferred from usage strings/entitlements where
  possible; absence here does not guarantee the app cannot request them.

## 7. Use in CI

`appxray` exits non-zero (`3`) when a high-risk flag is present, so you can gate
a build or a vendored dependency:

```bash
appxray ./build/MyApp.app --markdown --out audit.md || {
  echo "::warning::App X-Ray raised a high-risk flag — see audit.md"
}
```
