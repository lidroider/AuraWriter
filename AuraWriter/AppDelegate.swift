import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var popupWindowController: PopupWindowController?
    private var agentManagerWindow: NSWindow?

    private var agentService: AgentService!
    private var preferencesService: PreferencesService!
    private var backendService: BackendService!
    private var accessibilityService: AccessibilityService!
    private var keyboardShortcutService: KeyboardShortcutService!

    private var cancellables = Set<AnyCancellable>()

    private var revertState: RevertState?
    private var rewriteTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        do {
            try initializeServices()
        } catch {
            showError("Failed to initialize services: \(error.localizedDescription)")
            NSApp.terminate(nil)
            return
        }

        // Setup default agents if needed
        setupDefaultAgentsIfNeeded()

        // Check accessibility permission
        if !accessibilityService.checkPermission() {
            accessibilityService.requestPermission()
            showAccessibilityAlert()
        }

        // Setup menu bar
        setupMenuBar()

        // Register keyboard shortcut
        registerKeyboardShortcut()

        // Observe preferences changes
        observePreferencesChanges()
    }

    private func initializeServices() throws {
        agentService = AgentService()
        preferencesService = try PreferencesService()
        backendService = BackendService()
        accessibilityService = AccessibilityService()
        keyboardShortcutService = KeyboardShortcutService()
    }

    private func setupDefaultAgentsIfNeeded() {
        // Only setup defaults if no agents exist
        guard agentService.agents.isEmpty else { return }

        let defaultAgents: [Agent] = []

        for agent in defaultAgents {
            try? agentService.addAgent(agent)
        }

        // Show first launch alert
        showFirstLaunchAlert()
    }

    private func showFirstLaunchAlert() {
        let alert = NSAlert()
        alert.messageText = "Welcome to AuraWriter!"
        alert.informativeText = """
        To get started:
        1. Click the AuraWriter menu bar icon
        2. Select "Manage Agents"
        3. Add your first agent with your API key and custom prompt

        AuraWriter works with OpenAI API and any OpenAI-compatible endpoint.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it!")
        alert.runModal()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let customIcon = NSImage(named: "StatusBarIcon") {
                customIcon.isTemplate = true
                button.image = customIcon
            } else {
                button.image = NSImage(systemSymbolName: "pencil.circle", accessibilityDescription: "AuraWriter")
            }
            button.action = #selector(toggleMenu)
            button.target = self
        }
    }

    @objc private func toggleMenu() {
        guard let button = statusItem?.button else { return }

        let menuView = MenuBarView(
            agentService: agentService,
            preferencesService: preferencesService,
            onManageAgents: { [weak self] in
                self?.showAgentManager()
            },
            onRevert: { [weak self] in
                self?.handleRevert()
            },
            onQuit: {
                NSApp.terminate(nil)
            },
            onTemporarilyDisableHotkey: { [weak self] in
                self?.keyboardShortcutService.unregisterHotKey()
            },
            onReEnableHotkey: { [weak self] in
                self?.registerKeyboardShortcut()
            },
            onCloseMenu: { [weak self] in
                // Cancel the menu to close it immediately
                self?.statusItem?.menu?.cancelTracking()
                self?.statusItem?.menu = nil
            }
        )

        let hostingView = NSHostingView(rootView: menuView)
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: fittingSize.height)

        let menu = NSMenu()
        let menuItem = NSMenuItem()
        menuItem.view = hostingView
        menu.addItem(menuItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        // Clear menu after it's shown so next click works
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    private func registerKeyboardShortcut() {
        MainActor.assumeIsolated {
            let shortcut = preferencesService.preferences.keyboardShortcut

            let success = keyboardShortcutService.registerHotKey(
                key: shortcut.key,
                modifiers: shortcut.modifiers
            ) { [weak self] in
                self?.handleKeyboardShortcut()
            }

            if !success {
                showError("Failed to register keyboard shortcut")
            }
        }
    }

    private func observePreferencesChanges() {
        preferencesService.$preferences
            .dropFirst() // Skip initial value
            .sink { [weak self] newPreferences in
                guard let self = self else { return }
                // Re-register keyboard shortcut when preferences change
                self.registerKeyboardShortcut()
            }
            .store(in: &cancellables)

        // Also listen for manual notification as backup
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShortcutChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerKeyboardShortcut()
        }
    }

    private func handleRevert() {
        guard let state = revertState, !state.isExpired else {
            showError("No recent change to revert, or change has expired (5 minute limit)")
            return
        }

        // Check if we're in the same app
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              currentApp.bundleIdentifier == state.targetApp.bundleIdentifier else {
            showError("Cannot revert: switch back to the app where the text was changed")
            return
        }

        do {
            let (_, element, currentRange) = try accessibilityService.getSelectedText()

            // Convert NSRange to CFRange
            let cfRange = CFRange(location: state.replacedRange.location, length: state.replacedRange.length)

            // Replace with original text
            try accessibilityService.replaceSelectedText(
                element: element,
                range: cfRange,
                newText: state.originalText
            )

            // Clear revert state after successful revert
            revertState = nil

            // Show brief confirmation (optional)
            print("Reverted to original text")
        } catch {
            showError("Failed to revert: \(error.localizedDescription)")
        }
    }

    private func handleKeyboardShortcut() {
        do {
            let (text, element, range) = try accessibilityService.getSelectedText()
            showPopup(selectedText: text, element: element, range: range)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showPopup(selectedText: String, element: AXUIElement, range: CFRange) {
        let contentView = PopupContentView(
            agentService: agentService,
            preferencesService: preferencesService,
            selectedText: selectedText,
            onRewrite: { [weak self] agent in
                self?.performRewrite(agent: agent, element: element, range: range, originalText: selectedText)
            },
            onCancel: { [weak self] in
                self?.closePopup()
            }
        )

        popupWindowController = PopupWindowController(contentView: contentView)
        popupWindowController?.showAtMouseLocation()
    }

    private func closePopup() {
        popupWindowController?.close()
        popupWindowController = nil
    }

    private func performRewrite(agent: Agent, element: AXUIElement, range: CFRange, originalText: String) {
        rewriteTask = Task {
            do {
                let rewrittenText = try await backendService.rewriteText(agent: agent, selectedText: originalText)

                await MainActor.run {
                    do {
                        // Close popup after successful API call
                        closePopup()

                        // Focus the target app before replacing text
                        accessibilityService.focusApplication(for: element)

                        try accessibilityService.replaceSelectedText(element: element, range: range, newText: rewrittenText)

                        // Store revert state
                        if let app = NSWorkspace.shared.frontmostApplication {
                            revertState = RevertState(
                                originalText: originalText,
                                replacedRange: NSRange(location: range.location, length: range.length),
                                targetApp: app,
                                timestamp: Date()
                            )
                        }
                    } catch {
                        closePopup()
                        showError("Failed to replace text: \(error.localizedDescription)")
                    }
                }
            } catch {
                await MainActor.run {
                    closePopup()

                    let errorMessage: String
                    if let backendError = error as? BackendError {
                        switch backendError {
                        case .invalidURL:
                            errorMessage = "Invalid backend URL for agent '\(agent.name)'"
                        case .networkError(let underlyingError):
                            errorMessage = "Network error: \(underlyingError.localizedDescription)"
                        case .invalidResponse:
                            errorMessage = "Invalid response from backend. Check your API key and backend URL."
                        case .emptyResponse:
                            errorMessage = "Backend returned empty response"
                        case .timeout:
                            errorMessage = "Request timed out after 30 seconds"
                        }
                    } else {
                        errorMessage = "Failed to rewrite text: \(error.localizedDescription)"
                    }
                    showError(errorMessage)
                }
            }
        }
    }

    private func cancelRewrite() {
        rewriteTask?.cancel()
        rewriteTask = nil
    }

    private func showAgentManager() {
        // Close the menu bar first
        statusItem?.menu?.cancelTracking()
        statusItem?.menu = nil

        if agentManagerWindow == nil {
            let contentView = AgentListView(agentService: agentService)
            let hostingView = NSHostingView(rootView: contentView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Manage Agents"
            window.contentView = hostingView
            window.center()
            window.setFrameAutosaveName("AgentManager")
            window.isReleasedWhenClosed = false
            window.delegate = self

            agentManagerWindow = window
        }

        agentManagerWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Ensure window gets focus
        DispatchQueue.main.async { [weak self] in
            self?.agentManagerWindow?.makeKey()
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == agentManagerWindow else { return }
        agentManagerWindow = nil
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "AuraWriter needs accessibility permission to read and replace selected text.\n\nPlease enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
