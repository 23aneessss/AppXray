import Foundation

public extension AppReport {
    /// A one-paragraph, plain-language summary of the most important signals —
    /// honest framing, no fabricated safety score.
    var summary: String {
        var parts: [String] = []

        let signer: String
        switch signature.kind {
        case .developerID: signer = "signed by an identified developer" + (signature.teamID.map { " (team \($0))" } ?? "")
        case .appleSystem: signer = "Apple system software"
        case .appleDevelopment: signer = "a development build"
        case .adhoc: signer = "ad-hoc signed (no identity)"
        case .unsigned: signer = "unsigned"
        case .other: signer = "signed"
        }
        parts.append("\(name) is \(signer).")

        parts.append(isSandboxed ? "It runs in the App Sandbox." : "It is not sandboxed.")
        if signature.kind == .developerID {
            parts.append(isNotarized ? "It is notarized." : "It is not notarized.")
        }

        let capabilities = badges.filter { $0.isOn && $0.risk >= .notable }.map(\.label)
        if capabilities.isEmpty {
            parts.append("No notable capability flags were raised.")
        } else {
            parts.append("Notable capabilities: \(capabilities.joined(separator: ", ")).")
        }

        let highCount = warnings.filter { $0.risk == .high }.count
        if highCount > 0 {
            parts.append("\(highCount) high-risk flag\(highCount == 1 ? "" : "s") — review the warnings.")
        }

        return parts.joined(separator: " ")
    }

    /// The highest risk level present anywhere in the report. Useful for CI gating.
    var highestRisk: RiskLevel {
        var highest: RiskLevel = .info
        for w in warnings { highest = max(highest, w.risk) }
        for e in entitlements { highest = max(highest, e.risk) }
        for b in badges where b.isOn { highest = max(highest, b.risk) }
        return highest
    }
}
