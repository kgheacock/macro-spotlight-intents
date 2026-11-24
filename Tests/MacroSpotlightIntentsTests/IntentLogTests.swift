import Testing
@testable import MacroSpotlightIntents

private struct BodyError: Error {}

@Suite struct IntentLogTests {
    @Test func returnsBodyValue() async throws {
        let value = try await IntentLog.run("IntentLogTests") { 42 }
        #expect(value == 42)
    }

    @Test func rethrowsBodyError() async {
        await #expect(throws: BodyError.self) {
            try await IntentLog.run("IntentLogTests") { () async throws -> Int in
                throw BodyError()
            }
        }
    }
}
