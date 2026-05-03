import XCTest
@testable import AuraWriter

final class PreferencesTests: XCTestCase {
    func testPreferencesCodable() throws {
        let prefs = Preferences(
            keyboardShortcut: KeyboardShortcut(key: "A", modifiers: [.command, .shift]),
            defaultAgentPerApp: ["com.apple.Notes": UUID()],
            lastUsedAgentID: UUID()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Preferences.self, from: data)

        XCTAssertEqual(decoded.keyboardShortcut.key, prefs.keyboardShortcut.key)
        XCTAssertEqual(decoded.keyboardShortcut.modifiers, prefs.keyboardShortcut.modifiers)
        XCTAssertEqual(decoded.defaultAgentPerApp, prefs.defaultAgentPerApp)
        XCTAssertEqual(decoded.lastUsedAgentID, prefs.lastUsedAgentID)
    }

    func testPreferencesDefaultInitialization() {
        let prefs = Preferences()

        XCTAssertEqual(prefs.keyboardShortcut.key, "A")
        XCTAssertEqual(prefs.keyboardShortcut.modifiers, [.command, .shift])
        XCTAssertEqual(prefs.defaultAgentPerApp.count, 0)
        XCTAssertNil(prefs.lastUsedAgentID)
    }

    func testPreferencesCodableWithEmptyDefaults() throws {
        let prefs = Preferences(
            keyboardShortcut: KeyboardShortcut(key: "B", modifiers: [.control]),
            defaultAgentPerApp: [:],
            lastUsedAgentID: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Preferences.self, from: data)

        XCTAssertEqual(decoded.keyboardShortcut.key, "B")
        XCTAssertEqual(decoded.keyboardShortcut.modifiers, [.control])
        XCTAssertEqual(decoded.defaultAgentPerApp.count, 0)
        XCTAssertNil(decoded.lastUsedAgentID)
    }
}
