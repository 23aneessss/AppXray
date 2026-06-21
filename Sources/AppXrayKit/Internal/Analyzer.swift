import Foundation

/// Orchestrates the inspectors and assembles a complete ``AppReport``.
///
/// This is the heart of AppXrayKit: it runs each inspector, maps raw
/// entitlements through the ``EntitlementsCatalog``, derives the at-a-glance
/// capability badges, and distils the most important signals into plain-language
/// warnings.
struct Analyzer {

    func analyze(bundleAt url: URL) throws -> AppReport {
        let bundleURL = url.standardizedFileURL
        Log.inspector.info("Analyzing \(bundleURL.path, privacy: .public)")

        // 1. Bundle / Info.plist
        let bundle = try BundleInspector(bundleURL: bundleURL).inspect()

        // 2. Signature + entitlements (native Security.framework)
        let sig = try SignatureInspector(bundleURL: bundleURL).inspect()

        // 3. Mach-O: architectures + linked libraries
        let macho = bundle.executableURL.flatMap { MachOReader(url: $0).read() }
        let architectures = macho?.architectures ?? []
        let libraries = macho?.libraries ?? []
        let privateFrameworks = libraries.filter(\.isPrivateFramework).map(\.path)

        // 4. Gatekeeper assessment
        let gatekeeper = NotarizationInspector(bundleURL: bundleURL).gatekeeperAccepts()

        // 5. Nested components
        let nested = NestedComponentInspector(bundleURL: bundleURL).inspect()

        // 6. Persistence / background
        let persistence = PersistenceInspector(
            bundleURL: bundleURL,
            isUIElement: bundle.isUIElement,
            isBackgroundOnly: bundle.isBackgroundOnly
        ).inspect()

        // 7. Network hints (heuristic, labelled)
        let networkHints = NetworkHintsScanner(executableURL: bundle.executableURL).scan()

        // 8. Entitlement findings & associated domains
        let entitlementFindings = Self.entitlementFindings(sig.entitlements)
        let associatedDomains = Self.associatedDomains(sig.entitlements)

        // 9. Badges & warnings (derived)
        let badges = Self.badges(
            signature: sig, architectures: architectures, libraries: libraries,
            entitlements: sig.entitlements, privacyUsage: bundle.privacyUsage,
            persistence: persistence
        )
        let warnings = Self.warnings(
            signature: sig, isNotarized: sig.isNotarized, architectures: architectures,
            entitlementFindings: entitlementFindings, nested: nested, persistence: persistence
        )

        return AppReport(
            bundlePath: bundleURL.path,
            name: bundle.name,
            bundleID: bundle.bundleID,
            version: bundle.version,
            minimumOS: bundle.minimumOS,
            architectures: architectures,
            isSandboxed: sig.isSandboxed,
            isNotarized: sig.isNotarized,
            gatekeeperAccepted: gatekeeper,
            signature: sig.signature,
            entitlements: entitlementFindings,
            privacyUsage: bundle.privacyUsage,
            linkedLibraries: libraries,
            privateFrameworks: privateFrameworks,
            nestedComponents: nested,
            urlSchemes: bundle.urlSchemes,
            associatedDomains: associatedDomains,
            networkHints: networkHints,
            badges: badges,
            warnings: warnings
        )
    }

    // MARK: - Entitlements → findings

    static func entitlementFindings(_ entitlements: [String: Any]) -> [EntitlementFinding] {
        entitlements
            .map { key, value -> EntitlementFinding in
                let rendered = renderValue(value)
                if let info = EntitlementsCatalog.resolve(key) {
                    // A boolean entitlement set to false isn't really "held".
                    let risk = (value as? Bool) == false ? .info : info.risk
                    return EntitlementFinding(key: key, valueDescription: rendered,
                                              title: info.title, explanation: info.explanation, risk: risk)
                }
                return EntitlementFinding(key: key, valueDescription: rendered, title: key,
                                          explanation: "Entitlement not in App X-Ray's catalog; listed for transparency.",
                                          risk: .info)
            }
            .sorted { ($0.risk, $0.key) > ($1.risk, $1.key) }
    }

    static func associatedDomains(_ entitlements: [String: Any]) -> [String] {
        (entitlements["com.apple.developer.associated-domains"] as? [String])?.sorted() ?? []
    }

    static func renderValue(_ value: Any) -> String {
        switch value {
        case let b as Bool: return b ? "true" : "false"
        case let s as String: return s
        case let n as NSNumber: return n.stringValue
        case let arr as [Any]: return arr.count == 1 ? "1 item" : "\(arr.count) items"
        default: return String(describing: value)
        }
    }

    // MARK: - Badges

    static func badges(
        signature sig: SignatureInspector.Result,
        architectures: [String],
        libraries: [LinkedLibrary],
        entitlements: [String: Any],
        privacyUsage: [PrivacyUsageFinding],
        persistence: PersistenceInspector.Result
    ) -> [CapabilityBadge] {
        func has(_ key: String) -> Bool { (entitlements[key] as? Bool) == true }
        func usage(_ resource: String) -> Bool { privacyUsage.contains { $0.resource.hasPrefix(resource) } }

        let isUniversal = architectures.contains("x86_64")
            && architectures.contains { $0.hasPrefix("arm64") }
        let canScreenRecord = usage("Screen Recording")
        let canCamera = has("com.apple.security.device.camera") || usage("Camera")
        let canMic = has("com.apple.security.device.microphone")
            || has("com.apple.security.device.audio-input") || usage("Microphone")
        let canControlApps = has("com.apple.security.automation.apple-events") || usage("Automation")
        let linksPrivate = libraries.contains { $0.isPrivateFramework }
        let installsBackground = !persistence.bundledLaunchAgents.isEmpty
            || !persistence.bundledLaunchDaemons.isEmpty || !persistence.loginItems.isEmpty

        return [
            CapabilityBadge(label: "Sandboxed", isOn: sig.isSandboxed,
                            risk: sig.isSandboxed ? .info : .notable),
            CapabilityBadge(label: "Notarized", isOn: sig.isNotarized,
                            risk: sig.isNotarized ? .info : .notable),
            CapabilityBadge(label: "Hardened Runtime", isOn: sig.signature.hardenedRuntime,
                            risk: sig.signature.hardenedRuntime ? .info : .notable),
            CapabilityBadge(label: "Can record screen", isOn: canScreenRecord,
                            risk: canScreenRecord ? .notable : .info),
            CapabilityBadge(label: "Can access camera", isOn: canCamera,
                            risk: canCamera ? .notable : .info),
            CapabilityBadge(label: "Can access microphone", isOn: canMic,
                            risk: canMic ? .notable : .info),
            CapabilityBadge(label: "Can control other apps", isOn: canControlApps,
                            risk: canControlApps ? .notable : .info),
            CapabilityBadge(label: "Links private frameworks", isOn: linksPrivate,
                            risk: linksPrivate ? .notable : .info),
            CapabilityBadge(label: "Installs background items", isOn: installsBackground,
                            risk: installsBackground ? .notable : .info),
            CapabilityBadge(label: "Universal binary", isOn: isUniversal, risk: .info)
        ]
    }

    // MARK: - Warnings

    static func warnings(
        signature sig: SignatureInspector.Result,
        isNotarized: Bool,
        architectures: [String],
        entitlementFindings: [EntitlementFinding],
        nested: [NestedComponent],
        persistence: PersistenceInspector.Result
    ) -> [Finding] {
        var warnings: [Finding] = []

        switch sig.signature.kind {
        case .unsigned:
            warnings.append(Finding(
                title: "Unsigned code",
                detail: "This app has no code signature. Its origin and integrity cannot be verified.",
                risk: .high))
        case .adhoc:
            warnings.append(Finding(
                title: "Ad-hoc signed",
                detail: "Signed without an identity. The developer cannot be identified and the app is not notarized.",
                risk: .notable))
        case .appleDevelopment:
            warnings.append(Finding(
                title: "Development build",
                detail: "Signed with a development certificate — not meant for public distribution.",
                risk: .notable))
        case .developerID where !isNotarized:
            warnings.append(Finding(
                title: "Identified developer, not notarized",
                detail: "Signed with a Developer ID but no notarization ticket was recognised.",
                risk: .notable))
        case .developerID, .appleSystem, .other:
            break
        }

        if sig.signature.isDebuggable && sig.signature.kind != .appleDevelopment {
            warnings.append(Finding(
                title: "Debuggable in shipping build",
                detail: "The get-task-allow entitlement lets other processes inspect this app. Unexpected outside development.",
                risk: .notable))
        }

        if !sig.isSandboxed {
            warnings.append(Finding(
                title: "Not sandboxed",
                detail: "The app does not run in the App Sandbox, so OS-level file/hardware restrictions do not apply.",
                risk: .notable))
        }

        // Surface high-risk entitlements as explicit warnings (deduped by family,
        // e.g. multiple temporary-exception keys collapse to one warning).
        var seenHighTitles = Set<String>()
        for finding in entitlementFindings where finding.risk == .high {
            guard seenHighTitles.insert(finding.title).inserted else { continue }
            warnings.append(Finding(title: finding.title, detail: finding.explanation, risk: .high))
        }

        // x86-only on Apple Silicon era.
        if !architectures.isEmpty && !architectures.contains(where: { $0.hasPrefix("arm64") }) {
            warnings.append(Finding(
                title: "No Apple Silicon (arm64) slice",
                detail: "Runs only under Rosetta 2 translation on Apple Silicon Macs.",
                risk: .info))
        }

        // Unsigned nested code.
        for component in nested where component.signingSummary == "unsigned" {
            warnings.append(Finding(
                title: "Unsigned nested component",
                detail: "\(component.kind) at \(component.path) is unsigned.",
                risk: .notable))
        }

        return warnings.sorted { $0.risk > $1.risk }
    }
}
