import Foundation
import Security

/// Asks the system whether Gatekeeper would accept the app for execution, via
/// `SecAssessmentCreate`.
///
/// Note: this reflects the machine's *current* assessment policy. The
/// authoritative notarization signal is the `SecRequirement("notarized")` check
/// in ``SignatureInspector`` — `spctl`/assessment can be locally overridden
/// (see Appendix A.4), so App X-Ray reports the two separately.
struct NotarizationInspector {

    let bundleURL: URL

    /// Whether Gatekeeper would currently accept this app for execution.
    func gatekeeperAccepts() -> Bool {
        let context: [CFString: Any] = [
            kSecAssessmentContextKeyOperation: kSecAssessmentOperationTypeExecute
        ]
        var error: Unmanaged<CFError>?
        let assessment = SecAssessmentCreate(
            bundleURL as CFURL,
            SecAssessmentFlags(kSecAssessmentDefaultFlags),
            context as CFDictionary,
            &error
        )
        if let error { error.release() }
        return assessment != nil
    }
}
