import Foundation
import OSLog

/// Wraps the work of one intent so every intent logs in the same format.
///
/// Call it from each `perform()`:
///
///     let value = try await IntentLog.run("MyIntent") { ... }
///
/// Lines written, all in the `intents` category:
/// - `<name> started` (notice)
/// - `<name> finished in <n> ms` (notice)
/// - `<name> failed after <n> ms: <error type>` (error)
///
/// The name, the duration, and the error type are public. The error text is
/// private, because a later intent can put user data in it.
enum IntentLog {
    static func run<T>(
        _ name: String,
        _ body: () async throws -> T
    ) async throws -> T {
        let clock = ContinuousClock()
        let start = clock.now
        AppLog.intents.notice("\(name, privacy: .public) started")
        do {
            let value = try await body()
            let ms = milliseconds(since: start, on: clock)
            AppLog.intents.notice("\(name, privacy: .public) finished in \(ms, privacy: .public) ms")
            return value
        } catch {
            let ms = milliseconds(since: start, on: clock)
            let kind = String(describing: type(of: error))
            AppLog.intents.error(
                "\(name, privacy: .public) failed after \(ms, privacy: .public) ms: \(kind, privacy: .public) (\(error.localizedDescription, privacy: .private))"
            )
            throw error
        }
    }

    private static func milliseconds(since start: ContinuousClock.Instant, on clock: ContinuousClock) -> Int {
        let parts = (clock.now - start).components
        return Int(parts.seconds) * 1000 + Int(parts.attoseconds / 1_000_000_000_000_000)
    }
}
