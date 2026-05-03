import Cocoa
import Carbon

class KeyboardShortcutService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    deinit {
        unregisterHotKey()
    }

    func registerHotKey(key: String, modifiers: [AppKeyboardShortcut.Modifier], callback: @escaping () -> Void) -> Bool {
        unregisterHotKey()

        guard let keyCode = keyCodeForString(key) else {
            return false
        }

        self.callback = callback

        var carbonModifiers: UInt32 = 0
        for modifier in modifiers {
            switch modifier {
            case .command:
                carbonModifiers |= UInt32(cmdKey)
            case .shift:
                carbonModifiers |= UInt32(shiftKey)
            case .option:
                carbonModifiers |= UInt32(optionKey)
            case .control:
                carbonModifiers |= UInt32(controlKey)
            }
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                service.callback?()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        guard status == noErr else {
            return false
        }

        var hotKeyID = EventHotKeyID(signature: OSType(0x41555241), id: 1) // 'AURA'
        let registerStatus = RegisterEventHotKey(UInt32(keyCode), carbonModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        return registerStatus == noErr
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        callback = nil
    }

    private func keyCodeForString(_ key: String) -> Int? {
        let keyMap: [String: Int] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4,
            "I": 34, "J": 38, "K": 40, "L": 37, "M": 46, "N": 45, "O": 31,
            "P": 35, "Q": 12, "R": 15, "S": 1, "T": 17, "U": 32, "V": 9,
            "W": 13, "X": 7, "Y": 16, "Z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
            "6": 22, "7": 26, "8": 28, "9": 25,
            "Space": 49, "Return": 36, "Tab": 48, "Delete": 51,
            "Escape": 53, "F1": 122, "F2": 120, "F3": 99, "F4": 118,
            "F5": 96, "F6": 97, "F7": 98, "F8": 100, "F9": 101,
            "F10": 109, "F11": 103, "F12": 111
        ]

        return keyMap[key.uppercased()]
    }
}
