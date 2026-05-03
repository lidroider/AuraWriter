import Cocoa
import ApplicationServices

enum AccessibilityError: Error, LocalizedError {
    case permissionDenied
    case noFocusedElement
    case noSelectedText
    case replacementFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Accessibility permission is required. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
        case .noFocusedElement:
            return "No text field is currently focused."
        case .noSelectedText:
            return "No text is selected."
        case .replacementFailed:
            return "Failed to replace the selected text."
        }
    }
}

class AccessibilityService {

    func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func getSelectedText() throws -> (text: String, element: AXUIElement, range: CFRange) {
        guard checkPermission() else {
            throw AccessibilityError.permissionDenied
        }

        let systemWideElement = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success, let element = focusedElement else {
            throw AccessibilityError.noFocusedElement
        }

        let axElement = unsafeBitCast(element, to: AXUIElement.self)

        var selectedTextRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextRangeAttribute as CFString, &selectedTextRange)

        guard rangeResult == .success, let rangeValue = selectedTextRange else {
            throw AccessibilityError.noSelectedText
        }

        let axValue = unsafeBitCast(rangeValue, to: AXValue.self)

        var range = CFRange(location: 0, length: 0)
        AXValueGetValue(axValue, .cfRange, &range)

        guard range.length > 0 else {
            throw AccessibilityError.noSelectedText
        }

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard textResult == .success, let text = selectedText as? String, !text.isEmpty else {
            throw AccessibilityError.noSelectedText
        }

        return (text, axElement, range)
    }

    func replaceSelectedText(element: AXUIElement, range: CFRange, newText: String) throws {
        guard checkPermission() else {
            throw AccessibilityError.permissionDenied
        }

        // Always use pasteboard method for reliability across all apps including browsers
        try replaceSelectedTextViaPasteboard(newText: newText)
    }

    func focusApplication(for element: AXUIElement) {
        // Get the PID of the application that owns this element
        var pid: pid_t = 0
        if AXUIElementGetPid(element, &pid) == .success {
            if let app = NSRunningApplication(processIdentifier: pid) {
                app.activate()
                // Small delay to ensure the app is focused
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
    }

    private func replaceSelectedTextViaPasteboard(newText: String) throws {
        let pasteboard = NSPasteboard.general
        let previousText = pasteboard.string(forType: .string)

        // Copy new text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)

        // Small delay to ensure clipboard is updated
        Thread.sleep(forTimeInterval: 0.05)

        // Simulate Cmd+V to paste
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw AccessibilityError.replacementFailed
        }

        // Key down Cmd+V
        guard let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            throw AccessibilityError.replacementFailed
        }
        keyVDown.flags = .maskCommand
        keyVDown.post(tap: .cghidEventTap)

        // Key up Cmd+V
        guard let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            throw AccessibilityError.replacementFailed
        }
        keyVUp.flags = .maskCommand
        keyVUp.post(tap: .cghidEventTap)

        // Wait for paste to complete
        Thread.sleep(forTimeInterval: 0.1)

        // Restore previous clipboard content
        pasteboard.clearContents()
        if let previous = previousText {
            pasteboard.setString(previous, forType: .string)
        }
    }

    func getValueForAttribute(_ element: AXUIElement, attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return result == .success ? value : nil
    }
}
