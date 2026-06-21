import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AppXrayKit

struct ContentView: View {
    @StateObject private var library = AppLibrary()
    @State private var search = ""
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .onAppear { library.loadInstalled() }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [10]))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { openPanel() } label: { Label("Open App…", systemImage: "plus") }
            }
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(library.filtered(search), selection: $library.selection) { app in
            HStack(spacing: 8) {
                Image(nsImage: app.icon)
                    .resizable().frame(width: 22, height: 22)
                Text(app.name).lineLimit(1)
            }
            .tag(app.url)
        }
        .searchable(text: $search, placement: .sidebar, prompt: "Search apps")
        .navigationTitle("App X-Ray")
        .frame(minWidth: 220)
        .onChange(of: library.selection) { newValue in
            if let url = newValue { library.analyze(url: url) }
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if library.isAnalyzing {
            ProgressView("Analyzing…").controlSize(.large)
        } else if let message = library.errorMessage {
            ContentUnavailableViewCompat(
                title: "Couldn't analyze",
                systemImage: "exclamationmark.triangle",
                description: message + "\n\nReading some apps may require Full Disk Access."
            )
        } else if let report = library.report {
            ReportView(report: report)
        } else {
            ContentUnavailableViewCompat(
                title: "Drop a .app to X-ray it",
                systemImage: "rays",
                description: "Drag any app here, pick one from the sidebar, or use Open App… — App X-Ray reads what it can really do, 100% offline."
            )
        }
    }

    // MARK: Actions

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            library.analyze(url: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url, url.pathExtension == "app" else { return }
            Task { @MainActor in library.analyze(url: url) }
        }
        return true
    }
}

/// A small back-port of `ContentUnavailableView` for macOS 13.
struct ContentUnavailableViewCompat: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 46))
                .foregroundStyle(.tertiary)
            Text(title).font(.title2).bold()
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
