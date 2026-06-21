import Foundation

/// Reads everything App X-Ray needs from the bundle structure and its
/// `Info.plist`: identity, URL schemes, privacy usage strings, associated
/// document types, and the enumeration of nested components.
struct BundleInspector {

    struct Result {
        var name: String
        var bundleID: String?
        var version: String?
        var minimumOS: String?
        var isUIElement: Bool
        var isBackgroundOnly: Bool
        var urlSchemes: [String]
        var privacyUsage: [PrivacyUsageFinding]
        var executableURL: URL?
        var infoPlist: [String: Any]
    }

    let bundleURL: URL

    /// Parse the bundle's `Info.plist` and surrounding structure.
    /// - Throws: ``AppXrayError/notABundle`` or ``AppXrayError/unreadable``.
    func inspect() throws -> Result {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: bundleURL.path, isDirectory: &isDir), isDir.boolValue,
              bundleURL.pathExtension == "app" else {
            throw AppXrayError.notABundle
        }

        let infoURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let info = plist as? [String: Any] else {
            Log.inspector.error("Could not read Info.plist at \(infoURL.path, privacy: .public)")
            throw AppXrayError.unreadable
        }

        let name = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? bundleURL.deletingPathExtension().lastPathComponent

        var version = info["CFBundleShortVersionString"] as? String
        if let build = info["CFBundleVersion"] as? String, let v = version, build != v {
            version = "\(v) (\(build))"
        }

        let executableName = info["CFBundleExecutable"] as? String
        let executableURL = executableName.map {
            bundleURL.appendingPathComponent("Contents/MacOS").appendingPathComponent($0)
        }

        return Result(
            name: name,
            bundleID: info["CFBundleIdentifier"] as? String,
            version: version,
            minimumOS: info["LSMinimumSystemVersion"] as? String,
            isUIElement: (info["LSUIElement"] as? Bool) ?? boolFromAny(info["LSUIElement"]),
            isBackgroundOnly: (info["LSBackgroundOnly"] as? Bool) ?? boolFromAny(info["LSBackgroundOnly"]),
            urlSchemes: Self.urlSchemes(from: info),
            privacyUsage: Self.privacyUsage(from: info),
            executableURL: executableURL,
            infoPlist: info
        )
    }

    // MARK: - Parsing helpers

    static func urlSchemes(from info: [String: Any]) -> [String] {
        guard let types = info["CFBundleURLTypes"] as? [[String: Any]] else { return [] }
        var schemes: [String] = []
        for type in types {
            if let s = type["CFBundleURLSchemes"] as? [String] {
                schemes.append(contentsOf: s)
            }
        }
        return schemes.sorted()
    }

    static func privacyUsage(from info: [String: Any]) -> [PrivacyUsageFinding] {
        var findings: [PrivacyUsageFinding] = []
        for (key, value) in info {
            guard let resource = PrivacyUsageCatalog.resource(forKey: key) else { continue }
            let reason = (value as? String) ?? ""
            findings.append(PrivacyUsageFinding(resource: resource, usageKey: key, statedReason: reason))
        }
        return findings.sorted { $0.resource < $1.resource }
    }
}

private func boolFromAny(_ value: Any?) -> Bool {
    if let b = value as? Bool { return b }
    if let n = value as? NSNumber { return n.boolValue }
    if let s = value as? String { return (s as NSString).boolValue }
    return false
}
