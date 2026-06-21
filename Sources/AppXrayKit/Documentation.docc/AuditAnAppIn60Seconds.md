# Audit any Mac app in 60 seconds

From zero to a full capability report with a handful of lines.

## Add the package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/23aneessss/AppXray.git", from: "0.1.0")
]
```

Then `import AppXrayKit` where you need it.

## Analyze a bundle

```swift
import AppXrayKit

let url = URL(fileURLWithPath: "/Applications/Spotify.app")
let report = try AppXray.analyze(bundleAt: url)
```

That single call runs every inspector and returns a fully-populated
``AppReport``.

## Read the headline signals

```swift
print(report.summary)
// "Spotify is signed by an identified developer (team 2FNC3A47ZF). It is not
//  sandboxed. It is notarized. Notable capabilities: Installs background items.
//  2 high-risk flags — review the warnings."

print("Sandboxed:", report.isSandboxed)
print("Notarized:", report.isNotarized)
print("Signing:", report.signature.kind)
```

## Inspect capabilities and risks

```swift
for badge in report.badges where badge.isOn {
    print("✓", badge.label, "—", badge.risk)
}

for warning in report.warnings where warning.risk == .high {
    print("🔴", warning.title, "—", warning.detail)
}

for entitlement in report.entitlements where entitlement.risk >= .notable {
    print(entitlement.title, "[\(entitlement.valueDescription)] —", entitlement.explanation)
}
```

## Export

```swift
let markdown = report.markdown()                 // share in an issue/PR
let json = try report.jsonData()                 // diff two versions over time
let highest = report.highestRisk                 // gate a CI pipeline
```

## Honest interpretation

Remember the framing: a badge being *on* means the app **can** do something, not
that it **does**. Apple system apps legitimately read as "not notarized," and
``networkHints`` are heuristic strings — not proof of any connection. App X-Ray
hands you the facts; the judgement is yours.
