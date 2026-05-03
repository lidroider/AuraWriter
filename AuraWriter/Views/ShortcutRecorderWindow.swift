import Cocoa
import AppKit

class ShortcutRecorderWindow: NSWindow {
    private var recordedKey: String?
    private var recordedModifiers: [AppKeyboardShortcut.Modifier] = []
    private var isRecording = false
    private var eventMonitor: Any?

    private let instructionLabel = NSTextField(labelWithString: "Press any key combination with modifiers...")
    private let shortcutLabel = NSTextField(labelWithString: "")
    private let saveButton = NSButton(title: "Save", target: nil, action: nil)
    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)

    var onSave: ((AppKeyboardShortcut) -> Void)?

    init(currentShortcut: AppKeyboardShortcut) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 160),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.title = "Record Keyboard Shortcut"
        self.titlebarAppearsTransparent = true
        self.center()
        self.isReleasedWhenClosed = false

        setupUI(currentShortcut: currentShortcut)

        // Auto-start recording when window opens
        DispatchQueue.main.async { [weak self] in
            self?.startRecording()
        }
    }

    private func setupUI(currentShortcut: AppKeyboardShortcut) {
        let contentView = NSView(frame: self.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        // Instruction label
        instructionLabel.frame = NSRect(x: 20, y: 90, width: 380, height: 20)
        instructionLabel.alignment = .center
        instructionLabel.font = NSFont.systemFont(ofSize: 13)
        instructionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(instructionLabel)

        // Shortcut display
        shortcutLabel.frame = NSRect(x: 20, y: 50, width: 380, height: 32)
        shortcutLabel.alignment = .center
        shortcutLabel.font = NSFont.systemFont(ofSize: 24, weight: .regular)
        shortcutLabel.stringValue = "Waiting..."
        shortcutLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(shortcutLabel)

        // Button container for proper spacing
        let buttonContainer = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 40))

        // Cancel button (left)
        cancelButton.frame = NSRect(x: 240, y: 8, width: 80, height: 24)
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        buttonContainer.addSubview(cancelButton)

        // Save button (right)
        saveButton.frame = NSRect(x: 328, y: 8, width: 80, height: 24)
        saveButton.target = self
        saveButton.action = #selector(saveShortcut)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.isEnabled = false
        saveButton.hasDestructiveAction = false
        buttonContainer.addSubview(saveButton)

        contentView.addSubview(buttonContainer)
        self.contentView = contentView
    }

    private func startRecording() {
        isRecording = true
        recordedKey = nil
        recordedModifiers = []

        instructionLabel.stringValue = "Press any key combination with modifiers..."
        shortcutLabel.stringValue = "Waiting..."
        shortcutLabel.textColor = .tertiaryLabelColor

        // Install event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecording = false

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
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

        // Require at least one modifier
        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }

        recordedKey = key
        recordedModifiers = modifiers

        let shortcut = AppKeyboardShortcut(key: key, modifiers: modifiers)
        shortcutLabel.stringValue = formatShortcut(shortcut)
        shortcutLabel.textColor = .labelColor
        shortcutLabel.font = NSFont.monospacedSystemFont(ofSize: 24, weight: .medium)
        instructionLabel.stringValue = "Shortcut recorded successfully"
        saveButton.isEnabled = true

        stopRecording()
    }

    @objc private func saveShortcut() {
        if let key = recordedKey, !recordedModifiers.isEmpty {
            let shortcut = AppKeyboardShortcut(key: key, modifiers: recordedModifiers)
            onSave?(shortcut)
            close()
        }
    }

    @objc private func cancel() {
        stopRecording()
        close()
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

    override func close() {
        stopRecording()
        super.close()
    }
}
