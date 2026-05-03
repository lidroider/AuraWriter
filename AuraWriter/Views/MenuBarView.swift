import SwiftUI

struct MenuBarView: View {
    @ObservedObject var agentService: AgentService
    @ObservedObject var preferencesService: PreferencesService

    let onManageAgents: () -> Void
    let onRevert: () -> Void
    let onQuit: () -> Void
    let onTemporarilyDisableHotkey: () -> Void
    let onReEnableHotkey: () -> Void
    let onCloseMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("AuraWriter")
                    .font(.headline)
                Text("AI-powered text rewriting")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Divider()

            // Agent list
            if !agentService.agents.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Agents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(agentService.agents.prefix(5)) { agent in
                        AgentMenuItem(agent: agent)
                    }

                    if agentService.agents.count > 5 {
                        Text("+ \(agentService.agents.count - 5) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                }

                Divider()
            }

            // Keyboard shortcut info
            Button(action: {
                onCloseMenu()
                openShortcutRecorder()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard Shortcut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(formatShortcut(preferencesService.preferences.keyboardShortcut))
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .padding()

            Divider()

            // Actions
            VStack(spacing: 0) {
                Button(action: {
                    onCloseMenu()
                    onManageAgents()
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Manage Agents")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Button(action: onRevert) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Revert Last Change")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Button(action: onQuit) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit AuraWriter")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func formatShortcut(_ shortcut: AppKeyboardShortcut) -> String {
        var parts: [String] = []

        for modifier in shortcut.modifiers {
            switch modifier {
            case .command:
                parts.append("⌘")
            case .shift:
                parts.append("⇧")
            case .option:
                parts.append("⌥")
            case .control:
                parts.append("⌃")
            }
        }

        parts.append(shortcut.key)

        return parts.joined(separator: "")
    }

    private func updateShortcut(_ newShortcut: AppKeyboardShortcut) {
        var updatedPreferences = preferencesService.preferences
        updatedPreferences.keyboardShortcut = newShortcut

        do {
            try preferencesService.savePreferences(updatedPreferences)
        } catch {
            print("Failed to save shortcut: \(error)")
        }
    }

    private func openShortcutRecorder() {
        let currentShortcut = preferencesService.preferences.keyboardShortcut

        // Close menu and disable hotkey
        onCloseMenu()

        // Small delay to ensure menu is closed before opening window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.onTemporarilyDisableHotkey()

            let window = ShortcutRecorderWindow(currentShortcut: currentShortcut)

            // Re-enable when window closes
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                self.onReEnableHotkey()
            }

            window.onSave = { [preferencesService] newShortcut in
                // Check if the shortcut actually changed
                if newShortcut.key == currentShortcut.key && newShortcut.modifiers == currentShortcut.modifiers {
                    return
                }

                var updatedPreferences = preferencesService.preferences
                updatedPreferences.keyboardShortcut = newShortcut

                do {
                    try preferencesService.savePreferences(updatedPreferences)

                    // Force notification to trigger re-registration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: NSNotification.Name("ShortcutChanged"), object: nil)
                    }
                } catch {
                    print("Failed to save shortcut: \(error)")
                }
            }

            // Show and focus the window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            // Ensure the window is focused
            DispatchQueue.main.async {
                window.makeKey()
            }
        }
    }
}

struct AgentMenuItem: View {
    let agent: Agent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain")
                .foregroundColor(.accentColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.body)
                Text(agent.backendURL)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
