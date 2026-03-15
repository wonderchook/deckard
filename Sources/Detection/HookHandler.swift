import Foundation

/// Processes hook events from Claude Code and updates tab state accordingly.
class HookHandler {
    weak var windowController: DeckardWindowController?

    func handle(_ message: ControlMessage, reply: @escaping (ControlResponse) -> Void) {
        switch message.command {

        // --- Hook events from Claude Code ---

        case "hook.session-start":
            if let surfaceId = message.surfaceId {
                windowController?.updateBadge(forSurfaceId: surfaceId, state: .active)
            }
            reply(ControlResponse(ok: true))

        case "hook.stop":
            // Claude finished responding — waiting for user input
            if let surfaceId = message.surfaceId {
                windowController?.updateBadge(forSurfaceId: surfaceId, state: .waitingForInput)
            }
            reply(ControlResponse(ok: true))

        case "hook.notification":
            if let surfaceId = message.surfaceId {
                let type = message.notificationType ?? ""
                if type.contains("permission") {
                    windowController?.updateBadge(forSurfaceId: surfaceId, state: .needsPermission)
                } else {
                    windowController?.updateBadge(forSurfaceId: surfaceId, state: .waitingForInput)
                }
            }
            reply(ControlResponse(ok: true))

        case "hook.user-prompt-submit":
            // User typed something — Claude is working again
            if let surfaceId = message.surfaceId {
                windowController?.updateBadge(forSurfaceId: surfaceId, state: .active)
            }
            reply(ControlResponse(ok: true))

        case "hook.pre-tool-use":
            // Tool starting — Claude is active
            if let surfaceId = message.surfaceId {
                windowController?.updateBadge(forSurfaceId: surfaceId, state: .active)
            }
            reply(ControlResponse(ok: true))

        // --- Query commands ---

        case "list-tabs":
            let tabs = windowController?.listTabInfo() ?? []
            reply(ControlResponse(ok: true, tabs: tabs))

        case "create-tab":
            let isClaude = message.value != "terminal"
            windowController?.createTab(
                claude: isClaude,
                workingDirectory: message.workingDirectory,
                name: message.name
            )
            reply(ControlResponse(ok: true))

        case "ping":
            reply(ControlResponse(ok: true, message: "pong"))

        default:
            reply(ControlResponse(ok: false, error: "unknown command: \(message.command)"))
        }
    }
}
