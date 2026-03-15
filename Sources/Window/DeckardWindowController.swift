import AppKit
import GhosttyKit

/// Represents a single tab in the sidebar.
class TabItem {
    let id: UUID
    var surfaceView: TerminalNSView
    var name: String
    var nameOverride: Bool = false
    var isMaster: Bool = false
    var isClaude: Bool = true
    var sessionId: String?
    var workingDirectory: String?
    var badgeState: BadgeState = .none

    enum BadgeState {
        case none
        case active
        case waitingForInput
        case needsPermission
        case error
    }

    init(surfaceView: TerminalNSView, name: String, isClaude: Bool = true) {
        self.id = surfaceView.surfaceId
        self.surfaceView = surfaceView
        self.name = name
        self.isClaude = isClaude
    }
}

/// The main window controller with a vertical tab sidebar on the left.
class DeckardWindowController: NSWindowController, NSSplitViewDelegate {
    private let ghosttyApp: DeckardGhosttyApp
    private var tabs: [TabItem] = []
    private var selectedTabIndex: Int = -1

    // UI components
    private let splitView = NSSplitView()
    private let sidebarView = NSView()
    private let sidebarScrollView = NSScrollView()
    private let sidebarStackView = NSStackView()
    private let terminalContainerView = NSView()
    private var currentTerminalView: TerminalNSView?
    private var claudeTabCounter: Int = 0
    private var terminalTabCounter: Int = 0

    private let sidebarWidth: CGFloat = 210

    init(ghosttyApp: DeckardGhosttyApp) {
        self.ghosttyApp = ghosttyApp

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Deckard"
        window.minSize = NSSize(width: 600, height: 400)
        window.backgroundColor = ghosttyApp.defaultBackgroundColor

        // Disable macOS's own tab bar system
        window.tabbingMode = .disallowed

        super.init(window: window)

        // Restore saved frame or center
        window.setFrameAutosaveName("DeckardMainWindow")
        if !window.setFrameUsingName("DeckardMainWindow") {
            window.center()
        }

        setupUI()
        createTab(claude: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Main split: sidebar | terminal
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(splitView)

        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        // Sidebar container
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.wantsLayer = true
        sidebarView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor

        // Stack view for tab buttons (vertical list)
        sidebarStackView.orientation = .vertical
        sidebarStackView.alignment = .leading
        sidebarStackView.spacing = 1
        sidebarStackView.translatesAutoresizingMaskIntoConstraints = false

        sidebarScrollView.documentView = sidebarStackView
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.autohidesScrollers = true
        sidebarScrollView.scrollerStyle = .overlay
        sidebarScrollView.drawsBackground = false
        sidebarScrollView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(sidebarScrollView)

        NSLayoutConstraint.activate([
            sidebarScrollView.topAnchor.constraint(equalTo: sidebarView.topAnchor, constant: 8),
            sidebarScrollView.bottomAnchor.constraint(equalTo: sidebarView.bottomAnchor, constant: -8),
            sidebarScrollView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            sidebarScrollView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            sidebarStackView.widthAnchor.constraint(equalTo: sidebarScrollView.widthAnchor),
        ])

        // Terminal container
        terminalContainerView.translatesAutoresizingMaskIntoConstraints = false

        // Add to split view
        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(terminalContainerView)

        // Set initial sidebar width after layout
        DispatchQueue.main.async { [self] in
            splitView.setPosition(sidebarWidth, ofDividerAt: 0)
        }
    }

    // MARK: - NSSplitViewDelegate

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 80  // minimum sidebar width
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return min(300, splitView.bounds.width * 0.3)  // max 30% of window
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false  // don't allow sidebar to collapse
    }

    // MARK: - Tab Management

    static var defaultWorkingDirectory: String {
        get { UserDefaults.standard.string(forKey: "defaultWorkingDirectory") ?? NSHomeDirectory() + "/Documents" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultWorkingDirectory") }
    }

    func createTab(claude: Bool, workingDirectory: String? = nil, name: String? = nil) {
        guard let app = ghosttyApp.app else { return }

        let effectiveWorkingDirectory = workingDirectory ?? Self.defaultWorkingDirectory

        let surfaceView = TerminalNSView()
        let tabName: String
        if let name = name {
            tabName = name
        } else if claude {
            claudeTabCounter += 1
            tabName = "Claude Code #\(claudeTabCounter)"
        } else {
            terminalTabCounter += 1
            tabName = "Terminal #\(terminalTabCounter)"
        }
        let tab = TabItem(surfaceView: surfaceView, name: tabName, isClaude: claude)
        tab.workingDirectory = workingDirectory

        // For Claude tabs, start a normal shell and use initial_input
        // to launch claude. This way the shell is fully set up (PATH, etc.)
        // before claude runs, and our wrapper in Resources/bin/ intercepts it.
        var extraEnvVars: [String: String] = [:]
        if claude {
            extraEnvVars["DECKARD_SESSION_TYPE"] = "claude"
        }

        // For Claude tabs, start a shell and launch claude via initialInput.
        // "clear" hides the login message, "exec" replaces the shell so
        // closing claude closes the tab.
        let initialInput: String? = claude ? "clear && exec claude\n" : nil

        surfaceView.createSurface(
            app: app,
            tabId: tab.id,
            workingDirectory: effectiveWorkingDirectory,
            command: nil,
            envVars: extraEnvVars,
            initialInput: initialInput
        )

        tabs.append(tab)
        rebuildSidebar()
        selectTab(at: tabs.count - 1)
    }

    func closeCurrentTab() {
        guard selectedTabIndex >= 0, selectedTabIndex < tabs.count else { return }
        closeTab(at: selectedTabIndex)
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }

        let tab = tabs[index]
        tab.surfaceView.destroySurface()
        tab.surfaceView.removeFromSuperview()
        tabs.remove(at: index)

        rebuildSidebar()

        if tabs.isEmpty {
            selectedTabIndex = -1
            currentTerminalView = nil
            createTab(claude: false)
        } else {
            let newIndex = min(index, tabs.count - 1)
            selectTab(at: newIndex)
        }
    }

    func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }

        // Unfocus old
        if selectedTabIndex >= 0, selectedTabIndex < tabs.count {
            tabs[selectedTabIndex].surfaceView.surface.map { ghostty_surface_set_focus($0, false) }
        }

        selectedTabIndex = index

        // Swap terminal views
        currentTerminalView?.removeFromSuperview()

        let newView = tabs[index].surfaceView
        newView.translatesAutoresizingMaskIntoConstraints = false
        terminalContainerView.addSubview(newView)
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: terminalContainerView.topAnchor),
            newView.bottomAnchor.constraint(equalTo: terminalContainerView.bottomAnchor),
            newView.leadingAnchor.constraint(equalTo: terminalContainerView.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: terminalContainerView.trailingAnchor),
        ])
        currentTerminalView = newView

        // Focus the terminal
        window?.makeFirstResponder(newView)

        // Update sidebar highlight
        updateSidebarSelection()
    }

    func focusMasterSession() {
        if let masterIndex = tabs.firstIndex(where: { $0.isMaster }) {
            selectTab(at: masterIndex)
        }
    }

    func focusedSurface() -> ghostty_surface_t? {
        guard selectedTabIndex >= 0, selectedTabIndex < tabs.count else { return nil }
        return tabs[selectedTabIndex].surfaceView.surface
    }

    // MARK: - Surface Callbacks

    func setTitle(_ title: String, forSurface surface: ghostty_surface_t?) {
        guard let surface = surface else { return }
        for tab in tabs {
            if tab.surfaceView.surface == surface {
                // Store the terminal title but don't update the sidebar name.
                // Tab names are managed by Deckard (numbered by default,
                // later renamed by the master session).
                tab.surfaceView.title = title
                break
            }
        }
    }

    func setPwd(_ pwd: String, forSurface surface: ghostty_surface_t?) {
        guard let surface = surface else { return }
        for tab in tabs {
            if tab.surfaceView.surface == surface {
                tab.surfaceView.pwd = pwd
                break
            }
        }
    }

    func handleSurfaceClosedById(_ surfaceId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == surfaceId }) {
            closeTab(at: index)
        }
    }

    // MARK: - Sidebar Rendering

    private func rebuildSidebar() {
        sidebarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (i, tab) in tabs.enumerated() {
            let row = TabRowView(title: tab.isMaster ? "\u{2605} \(tab.name)" : tab.name,
                                 bold: tab.isMaster,
                                 index: i,
                                 target: self,
                                 action: #selector(tabRowClicked(_:)))
            sidebarStackView.addArrangedSubview(row)
            // Pin row to full width of stack view
            row.leadingAnchor.constraint(equalTo: sidebarStackView.leadingAnchor).isActive = true
            row.trailingAnchor.constraint(equalTo: sidebarStackView.trailingAnchor).isActive = true
        }

        updateSidebarSelection()
    }

    private func updateSidebarSelection() {
        for (i, view) in sidebarStackView.arrangedSubviews.enumerated() {
            if let row = view as? TabRowView {
                row.isSelected = (i == selectedTabIndex)
            }
        }
    }

    private func updateSidebarItem(at index: Int) {
        guard index >= 0, index < sidebarStackView.arrangedSubviews.count else { return }
        let tab = tabs[index]
        if let row = sidebarStackView.arrangedSubviews[index] as? TabRowView {
            row.title = tab.isMaster ? "\u{2605} \(tab.name)" : tab.name
        }
    }

    private func badgeColor(for state: TabItem.BadgeState) -> NSColor {
        switch state {
        case .none: return .clear
        case .active: return .systemGreen
        case .waitingForInput: return .systemBlue
        case .needsPermission: return .systemOrange
        case .error: return .systemRed
        }
    }

    // MARK: - Sidebar Actions

    @objc private func tabRowClicked(_ sender: TabRowView) {
        let index = sender.index
        if index >= 0, index < tabs.count {
            selectTab(at: index)
        }
    }

    private func renameTabAtIndex(_ index: Int) {
        guard index >= 0, index < tabs.count else { return }
        let tab = tabs[index]

        let alert = NSAlert()
        alert.messageText = "Rename Tab"
        alert.informativeText = "Enter a new name for this tab:"
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        input.stringValue = tab.name
        alert.accessoryView = input
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty {
                tab.name = newName
                tab.nameOverride = true
                updateSidebarItem(at: index)
            }
        }
    }
}

// MARK: - TabRowView

/// A clickable row in the sidebar representing one tab.
class TabRowView: NSView {
    var title: String {
        didSet { label.stringValue = title }
    }
    var isSelected: Bool = false {
        didSet { needsDisplay = true }
    }
    let index: Int
    private let label: NSTextField
    private weak var target: AnyObject?
    private let action: Selector

    init(title: String, bold: Bool, index: Int, target: AnyObject, action: Selector) {
        self.title = title
        self.index = index
        self.target = target
        self.action = action

        label = NSTextField(labelWithString: title)
        label.font = bold ? .boldSystemFont(ofSize: 12) : .systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        if isSelected {
            NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).setFill()
            bounds.fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        _ = target?.perform(action, with: self)
    }
}
