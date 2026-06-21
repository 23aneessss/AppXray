# How App X-Ray works

A tour of the inspectors that turn a `.app` bundle into an ``AppReport``.

## Overview

``AppXray/analyze(bundleAt:)`` runs a pipeline of focused inspectors and then
derives the at-a-glance badges and warnings from their combined output. Each
inspector is independent and reads one authoritative source.

### Bundle inspection

The bundle inspector parses `Contents/Info.plist` for identity (name, bundle id,
version, minimum macOS), custom URL schemes, the background-app flags
(`LSUIElement` / `LSBackgroundOnly`), and the `NS*UsageDescription` privacy
strings — the permission prompts an app *can* show, mapped to friendly resource
names. It produces ``PrivacyUsageFinding`` values.

### Signature inspection (`Security.framework`)

This is the trust backbone. Using `SecStaticCodeCreateWithPath` and
`SecCodeCopySigningInformation`, App X-Ray reads:

- the **signing identifier**, **Team ID**, and certificate **authority chain**;
- the **code-signing flags** — `CS_RUNTIME` (Hardened Runtime), `CS_ADHOC`, and
  `get-task-allow` (debuggable);
- the full **entitlements dictionary**.

The signing **kind** (``SignatureInfo/Kind``) is derived from the leaf authority
and Team ID: a `Developer ID Application:` leaf is ``SignatureInfo/Kind/developerID``,
`Apple Development:` is ``SignatureInfo/Kind/appleDevelopment``, a `Software Signing`
leaf with no Team ID is ``SignatureInfo/Kind/appleSystem``, and so on.

Notarization is checked the **reliable** way — by validating the code against the
`notarized` `SecRequirement` — rather than trusting `spctl`, which reflects the
machine's local Gatekeeper policy and can be overridden.

### Mach-O reading

A small, dependency-free reader parses fat (universal) and thin Mach-O files to
list CPU architectures and the dynamic libraries the binary links
(``LinkedLibrary``). Any load path under `/System/Library/PrivateFrameworks/` is
flagged as private/undocumented-API usage.

### Catalogs

Raw entitlement keys and usage-description keys are mapped to friendly titles,
plain-language explanations, and honest ``RiskLevel`` values via the
EntitlementsCatalog and PrivacyUsageCatalog. Unknown keys are still surfaced (as
``RiskLevel/info``) for full transparency.

### Derivation

Finally, the analyzer composes ``CapabilityBadge`` values (Sandboxed, Notarized,
Hardened Runtime, Can record screen, …) and distils the most important signals
into plain-language ``Finding`` warnings, ordered by severity.

## Topics

- ``AppXray``
- ``AppReport``
- ``SignatureInfo``
