import SwiftUI
import AppKit

struct ShortcutRecorderView: View {
    @Binding var shortcut: AppKeyboardShortcut
    @State private var isRecording = false
    @State private var recordedKey: String?
    @State private var recordedModifiers: [AppKeyboardShortcut.Modifier] = []
    @State private var showingRecorder = false

    var onSave: (AppKeyboardShortcut) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current shortcut: \(formatShortcut(shortcut))")
                .font(.system(.body, design: .monospaced))

            Button("Change Shortcut") {
                print("🖱️ Change Shortcut button clicked")
                showingRecorder = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showingRecorder) {
            ShortcutRecorderSheet(
                currentShortcut: shortcut,
                onSave: { newShortcut in
                    onSave(newShortcut)
                    showingRecorder = false
                },
                onCancel: {
                    showingRecorder = false
                }
            )
        }
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
}

struct ShortcutRecorderSheet: View {
    let currentShortcut: AppKeyboardShortcut
    let onSave: (AppKeyboardShortcut) -> Void
    let onCancel: () -> Void

    @State private var isRecording = false
    @State private var recordedKey: String?
    @State private var recordedModifiers: [AppKeyboardShortcut.Modifier] = []
    @State private var localEventMonitor: Any?
    @State private var globalEventMonitor: Any?

    var body: some View {
        VStack(spacing: 20) {
            Text("Record New Shortcut")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Current: \(formatShortcut(currentShortcut))")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                if let key = recordedKey, !recordedModifiers.isEmpty {
                    Text("New: \(formatShortcut(AppKeyboardShortcut(key: key, modifiers: recordedModifiers)))")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.green)
                } else if isRecording {
                    Text("Press any key with modifiers...")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.blue)
                } else {
                    Text("Click 'Start Recording' and press keys")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            if !isRecording {
                Button("Start Recording") {
                    print("🎬 Start Recording clicked")
                    startRecording()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("Stop Recording") {
                    print("🛑 Stop Recording clicked")
                    stopRecording()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    print("❌ Cancel clicked")
                    stopRecording()
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    print("💾 Save clicked")
                    if let key = recordedKey, !recordedModifiers.isEmpty {
                        onSave(AppKeyboardShortcut(key: key, modifiers: recordedModifiers))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(recordedKey == nil || recordedModifiers.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400, height: 300)
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordedKey = nil
        recordedModifiers = []

        print("🎯 Installing event monitors...")

        // Install local event monitor
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("🔵 Local key event: keyCode=\(event.keyCode)")
            self.handleKeyEvent(event)
            return nil
        }

        // Install global event monitor
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            print("🟢 Global key event: keyCode=\(event.keyCode)")
            self.handleKeyEvent(event)
        }

        print("✅ Event monitors installed")
    }

    private func stopRecording() {
        isRecording = false

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }

        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }

        print("🗑️ Event monitors removed")
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }

        let key = keyStringFromEvent(event)
        var modifiers: [AppKeyboardShortcut.Modifier] = []

        let flags = event.modifierFlags
        if flags.contains(.command) {
            modifiers.append(.command)
        }
        if flags.contains(.shift) {
            modifiers.append(.shift)
        }
        if flags.contains(.option) {
            modifiers.append(.option)
        }
        if flags.contains(.control) {
            modifiers.append(.control)
        }

        print("⌨️ Key: \(key), Modifiers: \(modifiers)")

        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }

        recordedKey = key
        recordedModifiers = modifiers
        stopRecording()
        print("✅ Shortcut recorded!")
    }

    private func keyStringFromEvent(_ event: NSEvent) -> String {
        switch Int(event.keyCode) {
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Escape"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default:
            if let characters = event.charactersIgnoringModifiers?.uppercased(), !characters.isEmpty {
                return characters
            }
            return "?"
        }
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
}
