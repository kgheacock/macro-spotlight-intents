import Foundation
import OSLog

/// Loggers for the whole app. The subsystem is the bundle identifier read at
/// runtime, so no signing identity appears in the source.
///
/// Read the output with:
/// `log stream --level info --predicate 'subsystem == "<bundle id>"'`
enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "MacroSpotlightIntents"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let intents = Logger(subsystem: subsystem, category: "intents")
}
