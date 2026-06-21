import Foundation

/// Detects how an app can persist or run in the background: bundled
/// `LaunchAgents`/`LaunchDaemons`, login items, and the `LSUIElement` /
/// `LSBackgroundOnly` flags that mark agent-style apps.
struct PersistenceInspector {

    struct Result {
        var bundledLaunchAgents: [String]
        var bundledLaunchDaemons: [String]
        var loginItems: [String]
        var runsInBackground: Bool
    }

    let bundleURL: URL
    let isUIElement: Bool
    let isBackgroundOnly: Bool

    func inspect() -> Result {
        let contents = bundleURL.appendingPathComponent("Contents")
        return Result(
            bundledLaunchAgents: relativePaths(in: contents.appendingPathComponent("Library/LaunchAgents")),
            bundledLaunchDaemons: relativePaths(in: contents.appendingPathComponent("Library/LaunchDaemons")),
            loginItems: relativePaths(in: contents.appendingPathComponent("Library/LoginItems")),
            runsInBackground: isUIElement || isBackgroundOnly
        )
    }

    private func relativePaths(in dir: URL) -> [String] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        return items
            .map { $0.path.replacingOccurrences(of: bundleURL.path + "/", with: "") }
            .sorted()
    }
}
