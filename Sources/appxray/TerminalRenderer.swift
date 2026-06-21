import Foundation
import AppXrayKit

/// Renders an ``AppReport`` as a clean, sectioned, colour-coded terminal report.
struct TerminalRenderer {
    let palette: Palette

    func render(_ r: AppReport) -> String {
        var out = ""
        func line(_ s: String = "") { out += s + "\n" }

        // Header
        line()
        line(palette.bold("  \(r.name)") + palette.dim("  \(r.version ?? "")"))
        if let id = r.bundleID { line(palette.dim("  \(id)")) }
        line(palette.dim("  \(r.architectures.joined(separator: ", "))"))
        line()
        line("  " + r.summary)
        line()

        // Badges
        line(palette.bold("  CAPABILITIES"))
        for badge in r.badges {
            let mark = badge.isOn ? palette.green("✓") : palette.dim("✗")
            let label = badge.isOn && badge.risk >= .notable ? palette.risk(badge.label, badge.risk) : badge.label
            line("    \(mark) \(label)")
        }
        line()

        // Signature
        line(palette.bold("  CODE SIGNATURE"))
        line("    Signing:    \(signingLabel(r.signature.kind))")
        if let team = r.signature.teamID { line("    Team ID:    \(team)") }
        line("    Hardened:   \(yesNo(r.signature.hardenedRuntime))")
        line("    Sandboxed:  \(yesNo(r.isSandboxed))")
        line("    Notarized:  \(yesNo(r.isNotarized))")
        if let leaf = r.signature.authorities.first { line(palette.dim("    Authority:  \(leaf)")) }
        line()

        // Warnings
        if !r.warnings.isEmpty {
            line(palette.bold("  WARNINGS"))
            for w in r.warnings {
                line("    \(palette.riskIcon(w.risk)) \(palette.risk(w.title, w.risk))")
                line(palette.dim("      \(w.detail)"))
            }
            line()
        }

        // Entitlements
        if !r.entitlements.isEmpty {
            line(palette.bold("  ENTITLEMENTS (\(r.entitlements.count))"))
            for e in r.entitlements {
                line("    \(palette.riskIcon(e.risk)) \(palette.risk(e.title, e.risk)) " + palette.dim("[\(e.valueDescription)]"))
            }
            line()
        }

        // Privacy usage
        if !r.privacyUsage.isEmpty {
            line(palette.bold("  PRIVACY RESOURCES IT CAN REQUEST"))
            for p in r.privacyUsage {
                line("    \(palette.cyan(p.resource))")
                if !p.statedReason.isEmpty { line(palette.dim("      “\(p.statedReason)”")) }
            }
            line()
        }

        // Private frameworks
        if !r.privateFrameworks.isEmpty {
            line(palette.bold("  PRIVATE / UNDOCUMENTED FRAMEWORKS"))
            for p in r.privateFrameworks { line(palette.dim("    \(p)")) }
            line()
        }

        // Nested components
        if !r.nestedComponents.isEmpty {
            line(palette.bold("  NESTED COMPONENTS (\(r.nestedComponents.count))"))
            for c in r.nestedComponents {
                let sb = c.sandboxed.map { $0 ? "sandboxed" : "not sandboxed" } ?? "—"
                line("    \(palette.cyan(c.kind)): \(c.path)")
                line(palette.dim("      \(c.signingSummary) · \(sb)"))
            }
            line()
        }

        // URL schemes / associated domains
        if !r.urlSchemes.isEmpty {
            line(palette.bold("  URL SCHEMES"))
            line("    " + r.urlSchemes.map { "\($0)://" }.joined(separator: "  "))
            line()
        }
        if !r.associatedDomains.isEmpty {
            line(palette.bold("  ASSOCIATED DOMAINS"))
            for d in r.associatedDomains { line("    \(d)") }
            line()
        }

        // Network hints
        if !r.networkHints.isEmpty {
            line(palette.bold("  NETWORK HINTS ") + palette.yellow("(heuristic — not proof of any connection)"))
            for h in r.networkHints { line(palette.dim("    \(h)")) }
            line()
        }

        line(palette.dim("  Static, offline analysis. Reports what the app CAN do, not what it DOES."))
        line()
        return out
    }

    private func yesNo(_ b: Bool) -> String { b ? palette.green("yes") : palette.yellow("no") }

    private func signingLabel(_ kind: SignatureInfo.Kind) -> String {
        switch kind {
        case .developerID: return palette.green("Developer ID")
        case .appleSystem: return palette.green("Apple system software")
        case .appleDevelopment: return palette.yellow("Apple Development build")
        case .adhoc: return palette.yellow("Ad-hoc (no identity)")
        case .unsigned: return palette.red("UNSIGNED")
        case .other: return "Other"
        }
    }
}
