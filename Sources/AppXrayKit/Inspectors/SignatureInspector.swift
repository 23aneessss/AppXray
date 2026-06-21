import Foundation
import Security

/// Reads the code signature of a bundle using `Security.framework`
/// (`SecStaticCode`), the preferred, native path. The API recipe here is the
/// one verified on macOS 26 / Xcode 26 (see the project's Appendix A): the
/// `kSecCS*` constants are `UInt32` on this SDK and must be OR'd as raw values
/// before being wrapped in `SecCSFlags`.
struct SignatureInspector {

    struct Result {
        var signature: SignatureInfo
        var entitlements: [String: Any]
        var isSandboxed: Bool
        var isNotarized: Bool
        /// True when there is no signature at all.
        var isUnsigned: Bool
    }

    let bundleURL: URL

    // CS_* code-signing flags (from <kern/cs_blobs.h>).
    private static let CS_ADHOC: UInt32 = 0x0000_0002
    private static let CS_RUNTIME: UInt32 = 0x0001_0000
    private static let CS_GET_TASK_ALLOW: UInt32 = 0x0000_0004

    func inspect() throws -> Result {
        var sc: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &sc) == errSecSuccess,
              let code = sc else {
            Log.signature.error("SecStaticCodeCreateWithPath failed for \(bundleURL.path, privacy: .public)")
            throw AppXrayError.signatureUnreadable
        }

        // Validity against no requirement: errSecCSUnsigned (-67062) when unsigned.
        let validity = SecStaticCodeCheckValidity(code, [], nil)
        let isUnsigned = (validity == errSecCSUnsigned)

        // SDK gotcha: combine kSecCS* as raw UInt32, then wrap.
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation | kSecCSRequirementInformation)
        var infoCF: CFDictionary?
        guard SecCodeCopySigningInformation(code, flags, &infoCF) == errSecSuccess,
              let info = infoCF as? [String: Any] else {
            if isUnsigned {
                return Result(
                    signature: SignatureInfo(kind: .unsigned, teamID: nil, signingIdentifier: nil,
                                             authorities: [], hardenedRuntime: false, isDebuggable: false),
                    entitlements: [:], isSandboxed: false, isNotarized: false, isUnsigned: true)
            }
            throw AppXrayError.signatureUnreadable
        }

        let identifier = info[kSecCodeInfoIdentifier as String] as? String
        let teamID = info[kSecCodeInfoTeamIdentifier as String] as? String
        let csFlags = (info[kSecCodeInfoFlags as String] as? NSNumber)?.uint32Value ?? 0
        let hardenedRuntime = (csFlags & Self.CS_RUNTIME) != 0
        let isAdhoc = (csFlags & Self.CS_ADHOC) != 0

        let entitlements = (info[kSecCodeInfoEntitlementsDict as String] as? [String: Any]) ?? [:]
        let getTaskAllow = (entitlements["com.apple.security.get-task-allow"] as? Bool) ?? false
            || (csFlags & Self.CS_GET_TASK_ALLOW) != 0

        let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate] ?? []
        let authorities = certs.compactMap { SecCertificateCopySubjectSummary($0) as String? }
        let leafAuthority = authorities.first

        let kind = Self.signingKind(isUnsigned: isUnsigned, isAdhoc: isAdhoc,
                                    hasCerts: !certs.isEmpty, leafAuthority: leafAuthority, teamID: teamID)

        let isSandboxed = (entitlements["com.apple.security.app-sandbox"] as? Bool) ?? false
        let isNotarized = Self.checkNotarized(code)

        let signature = SignatureInfo(
            kind: kind,
            teamID: teamID,
            signingIdentifier: identifier,
            authorities: authorities,
            hardenedRuntime: hardenedRuntime,
            isDebuggable: getTaskAllow
        )

        return Result(signature: signature, entitlements: entitlements,
                      isSandboxed: isSandboxed, isNotarized: isNotarized, isUnsigned: isUnsigned)
    }

    /// Derive the signing kind from the leaf authority, team id, and flags,
    /// per Appendix A.2.
    static func signingKind(isUnsigned: Bool, isAdhoc: Bool, hasCerts: Bool,
                            leafAuthority: String?, teamID: String?) -> SignatureInfo.Kind {
        if isUnsigned { return .unsigned }
        if isAdhoc || !hasCerts { return .adhoc }
        guard let leaf = leafAuthority else { return .other }

        if leaf.hasPrefix("Developer ID Application:") {
            return .developerID
        }
        if leaf.hasPrefix("Apple Development:") || leaf.hasPrefix("Apple Distribution:")
            || leaf.hasPrefix("3rd Party Mac Developer") || leaf.hasPrefix("Mac Developer:") {
            return .appleDevelopment
        }
        if teamID == nil && (leaf == "Software Signing" || leaf.hasSuffix("Signing")) {
            return .appleSystem
        }
        return .other
    }

    /// The reliable notarization check: validate against the `notarized`
    /// requirement. Status 0 == notarized (Appendix A.1). Do NOT trust `spctl`.
    static func checkNotarized(_ code: SecStaticCode) -> Bool {
        var req: SecRequirement?
        guard SecRequirementCreateWithString("notarized" as CFString, [], &req) == errSecSuccess,
              let req else { return false }
        return SecStaticCodeCheckValidity(code, [], req) == errSecSuccess
    }
}
