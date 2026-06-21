import SwiftUI
import AppKit
import AppXrayKit

/// A discovered application on disk, for the sidebar list.
struct InstalledApp: Identifiable, Hashable {
    let url: URL
    let name: String
    var id: URL { url }

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}

/// The view model: discovers installed apps and runs analyses off the main
/// thread, publishing results back on the main actor.
@MainActor
final class AppLibrary: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var selection: URL?
    @Published var report: AppReport?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    /// Enumerate `/Applications` and the user's `~/Applications`.
    func loadInstalled() {
        let fm = FileManager.default
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        var found: [InstalledApp] = []
        for root in roots {
            let items = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            for url in items where url.pathExtension == "app" {
                let name = fm.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
                found.append(InstalledApp(url: url, name: name))
            }
        }
        apps = found.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Analyze a bundle, updating `report` / `errorMessage` when done.
    func analyze(url: URL) {
        selection = url
        isAnalyzing = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                let report = try AppXray.analyze(bundleAt: url)
                await MainActor.run {
                    self.report = report
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "\(error)"
                    self.report = nil
                    self.isAnalyzing = false
                }
            }
        }
    }

    var filtered: (String) -> [InstalledApp] {
        { query in
            guard !query.isEmpty else { return self.apps }
            return self.apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }
}
