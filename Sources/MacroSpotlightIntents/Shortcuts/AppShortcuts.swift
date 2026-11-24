import AppIntents

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PingIntent(),
            phrases: ["Ping \(.applicationName)"],
            shortTitle: "Ping",
            systemImageName: "bolt.horizontal"
        )
    }
}
