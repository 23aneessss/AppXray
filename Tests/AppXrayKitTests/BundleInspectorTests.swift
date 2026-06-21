import XCTest
@testable import AppXrayKit

final class BundleInspectorTests: XCTestCase {
    var fixtures: FixtureBuilder!

    override func setUp() { fixtures = FixtureBuilder() }
    override func tearDown() { fixtures.cleanup() }

    func testReadsIdentity() throws {
        let app = try fixtures.makeApp(named: "Sample", info: [
            "CFBundleExecutable": "Sample",
            "CFBundleIdentifier": "com.example.sample",
            "CFBundleName": "Sample",
            "CFBundleDisplayName": "Sample Pro",
            "CFBundleShortVersionString": "2.1",
            "CFBundleVersion": "210",
            "LSMinimumSystemVersion": "13.0"
        ])
        let result = try BundleInspector(bundleURL: app).inspect()
        XCTAssertEqual(result.name, "Sample Pro")
        XCTAssertEqual(result.bundleID, "com.example.sample")
        XCTAssertEqual(result.version, "2.1 (210)")
        XCTAssertEqual(result.minimumOS, "13.0")
    }

    func testRejectsNonBundle() {
        let url = fixtures.root.appendingPathComponent("not-an-app")
        XCTAssertThrowsError(try BundleInspector(bundleURL: url).inspect()) { error in
            XCTAssertEqual(error as? AppXrayError, .notABundle)
        }
    }

    func testParsesURLSchemes() {
        let info: [String: Any] = [
            "CFBundleURLTypes": [
                ["CFBundleURLSchemes": ["myapp", "myapp-secure"]],
                ["CFBundleURLSchemes": ["aaa"]]
            ]
        ]
        XCTAssertEqual(BundleInspector.urlSchemes(from: info), ["aaa", "myapp", "myapp-secure"])
    }

    func testParsesPrivacyUsage() {
        let info: [String: Any] = [
            "NSCameraUsageDescription": "To scan documents",
            "NSMicrophoneUsageDescription": "For voice notes",
            "SomeUnrelatedKey": "ignored"
        ]
        let usage = BundleInspector.privacyUsage(from: info)
        XCTAssertEqual(usage.count, 2)
        XCTAssertEqual(usage.first?.resource, "Camera")
        XCTAssertEqual(usage.first?.statedReason, "To scan documents")
    }
}
