import AppKit
import SwiftTerm

/// Wraps a SwiftTerm LocalProcessTerminalView for use in Deckard's tab system.
/// This is the ONLY file that imports SwiftTerm — the rest of Deckard talks
/// to TerminalSurface through its public interface.
class TerminalSurface: NSObject {
    let surfaceId: UUID
    var tabId: UUID?
    var title: String = ""
    var pwd: String?
    var isAlive: Bool { !processExited }
    var onProcessExit: ((TerminalSurface) -> Void)?

    private let terminalView: LocalProcessTerminalView
    private var processExited = false

    /// The NSView to add to the view hierarchy.
    var view: NSView { terminalView }

    init(surfaceId: UUID = UUID()) {
        self.surfaceId = surfaceId
        self.terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        super.init()
    }
}
