import Testing
@testable import MacroSpotlightIntents

@Suite struct PingIntentTests {
    @Test func performCompletes() async throws {
        _ = try await PingIntent().perform()
    }

    @Test func messageIsStable() {
        #expect(PingIntent.message == "macro-spotlight-intents is working")
    }
}
