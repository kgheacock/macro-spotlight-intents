import AppIntents

/// Placeholder intent. It proves end to end that the app registers intents
/// with Spotlight and Shortcuts.
struct PingIntent: AppIntent {
    static let title: LocalizedStringResource = "Ping"
    static let description = IntentDescription("Checks that macro-spotlight-intents is working.")

    static let message = "macro-spotlight-intents is working"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialog = try await IntentLog.run("PingIntent") {
            IntentDialog(stringLiteral: Self.message)
        }
        return .result(dialog: dialog)
    }
}
