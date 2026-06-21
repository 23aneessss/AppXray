# ``AppXrayKit``

Read what a macOS app can *really* do — straight from its bundle and code
signature, 100% offline.

## Overview

`AppXrayKit` is the reusable engine behind [App X-Ray](https://github.com/23aneessss/AppXray).
You give it a `.app` bundle; it gives you an ``AppReport`` — an honest,
plain-language inventory of the app's capabilities, read from authoritative
sources (`Security.framework` and the Mach-O binary), never from self-declared
privacy labels.

```swift
import AppXrayKit

let report = try AppXray.analyze(bundleAt: URL(fileURLWithPath: "/Applications/Spotify.app"))

print(report.summary)
print("Sandboxed:", report.isSandboxed, "· Notarized:", report.isNotarized)
for badge in report.badges where badge.isOn {
    print("•", badge.label)
}

let markdown = report.markdown()
let json = try report.jsonData()
```

### Design principles

- **Honest framing.** No fabricated "safety score." Every signal carries an
  explained ``RiskLevel`` (``RiskLevel/info``, ``RiskLevel/notable``,
  ``RiskLevel/high``) and the reader draws the conclusions.
- **Static & offline.** The kit reads the bundle on disk; it never runs the app
  or touches the network.
- **Native first.** It prefers `Security.framework` and a hand-rolled Mach-O
  reader over shelling out, and has **no third-party runtime dependencies**.
- **Testable.** All public model types are `Sendable` + `Codable`, and the
  parsing logic is kept pure.

## Topics

### Getting started

- <doc:AuditAnAppIn60Seconds>
- ``AppXray``
- ``AppReport``

### Understanding the engine

- <doc:HowItWorks>

### The report

- ``AppReport``
- ``SignatureInfo``
- ``EntitlementFinding``
- ``PrivacyUsageFinding``
- ``LinkedLibrary``
- ``NestedComponent``
- ``CapabilityBadge``
- ``Finding``
- ``RiskLevel``

### Errors

- ``AppXrayError``
