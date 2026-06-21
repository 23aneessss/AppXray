import Foundation
import Security

/// Asks the system whether Gatekeeper would accept the app for execution.
///
/// The `SecAssessment` C API is not exposed to Swift, so this uses the
/// documented `spctl --assess` fallback. Note this reflects the machine's
/// *current* assessment policy — the authoritative notarization signal is the
/// native `SecRequirement("notarized")` check in ``SignatureInspector`` (see
/// Appendix A.4: `spctl` can be locally overridden, so the two are reported
/// separately).
struct NotarizationInspector {

    let bundleURL: URL

    /// Whether Gatekeeper would currently accept this app for execution.
    func gatekeeperAccepts() -> Bool {
        guard let result = Shell.run("/usr/sbin/spctl",
                                     ["--assess", "--type", "execute", bundleURL.path]) else {
            return false
        }
        return result.status == 0
    }
}
