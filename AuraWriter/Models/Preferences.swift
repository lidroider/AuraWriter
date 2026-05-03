import Foundation

struct AppKeyboardShortcut: Codable, Equatable {
    var key: String
    var modifiers: [Modifier]

    enum Modifier: String, Codable {
        case command
        case shift
        case option
        case control
    }
}

struct Preferences: Codable, Equatable {
    var keyboardShortcut: AppKeyboardShortcut
    var defaultAgentPerApp: [String: UUID]
    var lastUsedAgentID: UUID?

    init(
        keyboardShortcut: AppKeyboardShortcut = AppKeyboardShortcut(key: "A", modifiers: [.command, .shift]),
        defaultAgentPerApp: [String: UUID] = [:],
        lastUsedAgentID: UUID? = nil
    ) {
        self.keyboardShortcut = keyboardShortcut
        self.defaultAgentPerApp = defaultAgentPerApp
        self.lastUsedAgentID = lastUsedAgentID
    }
}
