import XCTest
@testable import AppXrayKit

/// End-to-end tests over a fixture bundle and the exporters.
final class AnalyzerPipelineTests: XCTestCase {
    var fixtures: FixtureBuilder!

    override func setUp() { fixtures = FixtureBuilder() }
    override func tearDown() { fixtures.cleanup() }

    func testAnalyzeUnsignedFixture() throws {
        let app = try fixtures.makeApp(named: "Widget", info: [
            "CFBundleExecutable": "Widget",
            "CFBundleIdentifier": "com.example.widget",
            "CFBundleShortVersionString": "1.0",
            "NSCameraUsageDescription": "Scan QR codes",
            "LSUIElement": true
        ])
        try fixtures.writeFile("Contents/Library/LaunchAgents/com.example.widget.agent.plist", in: app)

        let report = try AppXray.analyze(bundleAt: app)

        XCTAssertEqual(report.bundleID, "com.example.widget")
        XCTAssertEqual(report.signature.kind, .unsigned)
        XCTAssertFalse(report.isSandboxed)
        // Camera usage string surfaces as a privacy resource.
        XCTAssertTrue(report.privacyUsage.contains { $0.resource == "Camera" })
        // Unsigned → a high-risk warning exists, so highestRisk is .high.
        XCTAssertEqual(report.highestRisk, .high)
        XCTAssertTrue(report.warnings.contains { $0.title == "Unsigned code" })
        // Bundled LaunchAgent → "Installs background items" badge is on.
        XCTAssertTrue(report.badges.contains { $0.label == "Installs background items" && $0.isOn })
        // Not sandboxed badge off, etc.
        XCTAssertTrue(report.badges.contains { $0.label == "Sandboxed" && !$0.isOn })
    }

    func testMarkdownAndJSONRoundTrip() throws {
        let app = try fixtures.makeApp(named: "Mini", info: [
            "CFBundleExecutable": "Mini",
            "CFBundleIdentifier": "com.example.mini",
            "CFBundleShortVersionString": "1.0"
        ])
        let report = try AppXray.analyze(bundleAt: app)

        // Markdown contains the headline sections.
        let md = report.markdown()
        XCTAssertTrue(md.contains("# App X-Ray — Mini"))
        XCTAssertTrue(md.contains("## Code signature"))

        // JSON decodes back to an equal report.
        let data = try report.jsonData()
        let decoded = try JSONDecoder().decode(AppReport.self, from: data)
        XCTAssertEqual(decoded, report)
    }

    func testSummaryIsHonest() throws {
        let app = try fixtures.makeApp(named: "Mini", info: [
            "CFBundleExecutable": "Mini",
            "CFBundleIdentifier": "com.example.mini",
            "CFBundleShortVersionString": "1.0"
        ])
        let report = try AppXray.analyze(bundleAt: app)
        // No fabricated score — summary mentions signing and sandbox status.
        XCTAssertTrue(report.summary.contains("unsigned"))
        XCTAssertTrue(report.summary.contains("not sandboxed"))
    }
}
