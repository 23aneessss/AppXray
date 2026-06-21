import XCTest
@testable import AppXrayKit

final class CatalogTests: XCTestCase {

    func testKnownEntitlementResolves() {
        let info = EntitlementsCatalog.resolve("com.apple.security.app-sandbox")
        XCTAssertEqual(info?.title, "App Sandbox")
        XCTAssertEqual(info?.risk, .info)
    }

    func testSandboxEscapeIsHighRisk() {
        let info = EntitlementsCatalog.resolve("com.apple.security.temporary-exception.files.absolute-path.read-write")
        XCTAssertEqual(info?.risk, .high)
        XCTAssertEqual(info?.title, "Sandbox temporary exception")
    }

    func testLibraryValidationDisabledIsHigh() {
        XCTAssertEqual(EntitlementsCatalog.resolve("com.apple.security.cs.disable-library-validation")?.risk, .high)
    }

    func testUnknownEntitlementReturnsNil() {
        XCTAssertNil(EntitlementsCatalog.resolve("com.example.something.custom"))
    }

    func testPrivacyUsageMapping() {
        XCTAssertEqual(PrivacyUsageCatalog.resource(forKey: "NSCameraUsageDescription"), "Camera")
        XCTAssertEqual(PrivacyUsageCatalog.resource(forKey: "NSScreenCaptureUsageDescription"), "Screen Recording")
        XCTAssertNil(PrivacyUsageCatalog.resource(forKey: "CFBundleName"))
    }
}
