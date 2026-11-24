import SwiftUI

/// Menu bar host for the App Intents. The app has no window of its own: it
/// exists so macOS can register the intents that live in this bundle.
@main
struct MacroSpotlightIntentsApp: App {
    init() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "unknown"
        AppLog.app.notice("app launched version=\(version, privacy: .public) build=\(build, privacy: .public)")
    }

    var body: some Scene {
        MenuBarExtra("Macro Spotlight Intents", systemImage: "keyboard") {
            Text("macro-spotlight-intents")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
