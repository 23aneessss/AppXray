import XCTest
@testable import AppXrayKit

/// Tests for the pure derivation logic: signing-kind, Mach-O naming, badges,
/// entitlement findings, and network-hint extraction.
final class DerivationTests: XCTestCase {

    // MARK: Signing kind (Appendix A.2)

    func testSigningKindDeveloperID() {
        let kind = SignatureInspector.signingKind(
            isUnsigned: false, isAdhoc: false, hasCerts: true,
            leafAuthority: "Developer ID Application: Spotify (2FNC3A47ZF)", teamID: "2FNC3A47ZF")
        XCTAssertEqual(kind, .developerID)
    }

    func testSigningKindAppleSystem() {
        let kind = SignatureInspector.signingKind(
            isUnsigned: false, isAdhoc: false, hasCerts: true,
            leafAuthority: "Software Signing", teamID: nil)
        XCTAssertEqual(kind, .appleSystem)
    }

    func testSigningKindAppleDevelopment() {
        let kind = SignatureInspector.signingKind(
            isUnsigned: false, isAdhoc: false, hasCerts: true,
            leafAuthority: "Apple Development: Jane Doe (ABCDE12345)", teamID: "PBFNCNVLAL")
        XCTAssertEqual(kind, .appleDevelopment)
    }

    func testSigningKindUnsignedAndAdhoc() {
        XCTAssertEqual(SignatureInspector.signingKind(isUnsigned: true, isAdhoc: false, hasCerts: false,
                                                      leafAuthority: nil, teamID: nil), .unsigned)
        XCTAssertEqual(SignatureInspector.signingKind(isUnsigned: false, isAdhoc: true, hasCerts: false,
                                                      leafAuthority: nil, teamID: nil), .adhoc)
    }

    // MARK: Mach-O

    func testArchNaming() {
        XCTAssertEqual(MachOReader.archName(cpuType: 0x0100_0007, cpuSubtype: 3), "x86_64")
        XCTAssertEqual(MachOReader.archName(cpuType: 0x0100_000c, cpuSubtype: 0), "arm64")
        XCTAssertEqual(MachOReader.archName(cpuType: 0x0100_000c, cpuSubtype: 2), "arm64e")
    }

    func testPrivateFrameworkClassification() {
        let priv = MachOReader.classify(path: "/System/Library/PrivateFrameworks/Calculate.framework/Calculate", isWeak: false)
        XCTAssertTrue(priv.isPrivateFramework)
        XCTAssertTrue(priv.isSystem)

        let pub = MachOReader.classify(path: "/usr/lib/libSystem.B.dylib", isWeak: true)
        XCTAssertFalse(pub.isPrivateFramework)
        XCTAssertTrue(pub.isSystem)
        XCTAssertTrue(pub.isWeak)
    }

    // MARK: Entitlement findings

    func testEntitlementFindingsRiskAndFalseBool() {
        let findings = Analyzer.entitlementFindings([
            "com.apple.security.cs.disable-library-validation": true,
            "com.apple.security.app-sandbox": false,
            "com.example.unknown": "x"
        ])
        let libVal = findings.first { $0.key == "com.apple.security.cs.disable-library-validation" }
        XCTAssertEqual(libVal?.risk, .high)
        // A false boolean is not really "held" → downgraded to info.
        let sandbox = findings.first { $0.key == "com.apple.security.app-sandbox" }
        XCTAssertEqual(sandbox?.risk, .info)
        // Unknown keys are still surfaced.
        XCTAssertNotNil(findings.first { $0.key == "com.example.unknown" })
        // Sorted highest-risk first.
        XCTAssertEqual(findings.first?.risk, .high)
    }

    // MARK: Network hints

    func testHostExtraction() {
        let hosts = NetworkHintsScanner.extractHosts(from: "connect to https://api.example.com/v1/users and http://cdn.test.io/a")
        XCTAssertTrue(hosts.contains("https://api.example.com"))
        XCTAssertTrue(hosts.contains("http://cdn.test.io"))
    }

    func testRejectsImplausibleHosts() {
        XCTAssertFalse(NetworkHintsScanner.isPlausibleHost("localhost"[...]))   // no dot
        XCTAssertFalse(NetworkHintsScanner.isPlausibleHost("a.b"[...]))          // tld too short
        XCTAssertTrue(NetworkHintsScanner.isPlausibleHost("example.com"[...]))
    }
}
