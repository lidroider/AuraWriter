import XCTest
@testable import AuraWriter

final class PreferencesServiceTests: XCTestCase {
    var tempDirectory: URL!
    var preferencesService: PreferencesService!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            preferencesService = try PreferencesService(storageDirectory: tempDirectory)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testLoadDefaultPreferences() {
        let prefs = preferencesService.preferences
        XCTAssertEqual(prefs.keyboardShortcut.key, "A")
        XCTAssertEqual(prefs.keyboardShortcut.modifiers, [.command, .shift])
        XCTAssertEqual(prefs.defaultAgentPerApp.count, 0)
        XCTAssertNil(prefs.lastUsedAgentID)
    }

    func testSaveAndLoadPreferences() throws {
        let agentID = UUID()
        var prefs = Preferences()
        prefs.lastUsedAgentID = agentID
        prefs.defaultAgentPerApp["com.apple.Notes"] = agentID

        try preferencesService.savePreferences(prefs)

        XCTAssertEqual(preferencesService.preferences.lastUsedAgentID, agentID)
        XCTAssertEqual(preferencesService.preferences.defaultAgentPerApp["com.apple.Notes"], agentID)
    }

    func testSetDefaultAgentForApp() throws {
        let agentID = UUID()
        try preferencesService.setDefaultAgent(agentID, forApp: "com.apple.Notes")

        let prefs = preferencesService.preferences
        XCTAssertEqual(prefs.defaultAgentPerApp["com.apple.Notes"], agentID)
        XCTAssertEqual(prefs.lastUsedAgentID, agentID)
    }
}
