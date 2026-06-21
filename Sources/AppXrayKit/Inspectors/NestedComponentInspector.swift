import Foundation

/// Enumerates embedded bundles and executables inside an app: XPC services,
/// login items, helpers, embedded frameworks (including known updaters like
/// Sparkle), and command-line helpers — each with a mini signature summary.
struct NestedComponentInspector {

    let bundleURL: URL

    func inspect() -> [NestedComponent] {
        let contents = bundleURL.appendingPathComponent("Contents")
        var components: [NestedComponent] = []

        components += scan(contents.appendingPathComponent("XPCServices"), kind: "XPC Service", ext: "xpc")
        components += scan(contents.appendingPathComponent("Library/LoginItems"), kind: "Login Item", ext: "app")
        components += scan(contents.appendingPathComponent("PlugIns"), kind: "Plug-in", ext: nil)
        components += frameworks(in: contents.appendingPathComponent("Frameworks"))
        components += helpers(in: contents.appendingPathComponent("Helpers"))

        return components.sorted { $0.path < $1.path }
    }

    // MARK: - Scanners

    private func scan(_ dir: URL, kind: String, ext: String?) -> [NestedComponent] {
        children(of: dir)
            .filter { ext == nil || $0.pathExtension == ext }
            .map { component(at: $0, kind: kind) }
    }

    private func frameworks(in dir: URL) -> [NestedComponent] {
        children(of: dir)
            .filter { $0.pathExtension == "framework" }
            .map { url in
                let isSparkle = url.lastPathComponent == "Sparkle.framework"
                return component(at: url, kind: isSparkle ? "Updater (Sparkle)" : "Framework")
            }
    }

    private func helpers(in dir: URL) -> [NestedComponent] {
        children(of: dir).map { component(at: $0, kind: "Helper") }
    }

    // MARK: - Helpers

    private func children(of dir: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    }

    private func component(at url: URL, kind: String) -> NestedComponent {
        let relativePath = url.path.replacingOccurrences(of: bundleURL.path + "/", with: "")
        var summary = "no signature read"
        var sandboxed: Bool? = nil

        if let result = try? SignatureInspector(bundleURL: url).inspect() {
            sandboxed = result.isSandboxed
            summary = Self.summarize(result.signature)
        }

        return NestedComponent(kind: kind, path: relativePath, signingSummary: summary, sandboxed: sandboxed)
    }

    static func summarize(_ sig: SignatureInfo) -> String {
        switch sig.kind {
        case .unsigned: return "unsigned"
        case .adhoc: return "ad-hoc signed"
        case .appleSystem: return "Apple system"
        case .developerID:
            return "Developer ID" + (sig.teamID.map { " (\($0))" } ?? "")
        case .appleDevelopment: return "Apple Development"
        case .other: return sig.authorities.first ?? "signed"
        }
    }
}
