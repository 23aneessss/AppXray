import SwiftUI

@main
struct AppXrayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 880, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}   // no "New" — this is a viewer
        }
    }
}
