import Foundation

/// Builds tiny throwaway `.app` bundles on disk for tests, with a controllable
/// `Info.plist`. Lets us assert App X-Ray's parsing without shipping binaries.
struct FixtureBuilder {
    let root: URL

    init() {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("appxray-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: root)
    }

    /// Create a `.app` with the given Info.plist dictionary and an optional
    /// (non-Mach-O) executable stub. Returns the bundle URL.
    @discardableResult
    func makeApp(named name: String, info: [String: Any], makeExecutable: Bool = true) throws -> URL {
        let fm = FileManager.default
        let appURL = root.appendingPathComponent("\(name).app")
        let macOS = appURL.appendingPathComponent("Contents/MacOS")
        try fm.createDirectory(at: macOS, withIntermediateDirectories: true)

        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: appURL.appendingPathComponent("Contents/Info.plist"))

        if makeExecutable, let exec = info["CFBundleExecutable"] as? String {
            try Data("#!/bin/sh\n".utf8).write(to: macOS.appendingPathComponent(exec))
        }
        return appURL
    }

    /// Write a file relative to a bundle (e.g. a bundled LaunchAgent plist).
    func writeFile(_ relativePath: String, in app: URL, contents: String = "") throws {
        let url = app.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url)
    }
}
