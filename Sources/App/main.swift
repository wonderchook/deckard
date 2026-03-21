import AppKit
import GhosttyKit

// Install crash handlers as early as possible — before any Ghostty or AppKit
// work that could crash.
CrashReporter.install()
DiagnosticLog.shared.log("startup", "=== Deckard launch ===")
DiagnosticLog.shared.log("startup", "PID: \(ProcessInfo.processInfo.processIdentifier)")

// Surface any crash report left by a previous run.
CrashReporter.logPreviousCrashIfAny()

// Initialize the Ghostty library before anything else.
DiagnosticLog.shared.log("startup", "Calling ghostty_init...")
let ghosttyResult = ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv)
guard ghosttyResult == GHOSTTY_SUCCESS else {
    DiagnosticLog.shared.log("startup", "ghostty_init FAILED: \(ghosttyResult)")
    print("Failed to initialize ghostty: \(ghosttyResult)")
    exit(1)
}
DiagnosticLog.shared.log("startup", "ghostty_init succeeded")

// Launch the macOS application.
DiagnosticLog.shared.log("startup", "Creating NSApplication...")
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
DiagnosticLog.shared.log("startup", "Entering app.run()")
app.run()
