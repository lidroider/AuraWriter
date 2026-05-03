import Foundation
import AppKit
import Combine

@MainActor
class PreferencesService: ObservableObject {
    @Published var preferences: Preferences

    private let storageDirectory: URL
    private let preferencesFileName = "preferences.json"

    init(storageDirectory: URL? = nil) throws {
        if let directory = storageDirectory {
            self.storageDirectory = directory
        } else {
            self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("AuraWriter")
        }

        try FileManager.default.createDirectory(at: self.storageDirectory, withIntermediateDirectories: true)

        let fileURL = self.storageDirectory.appendingPathComponent(preferencesFileName)
        self.preferences = (try? Self.load(from: fileURL)) ?? Preferences()
    }

    private var preferencesFileURL: URL {
        storageDirectory.appendingPathComponent(preferencesFileName)
    }

    private static func load(from url: URL) throws -> Preferences {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return Preferences()
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Preferences.self, from: data)
    }

    func savePreferences(_ preferences: Preferences) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(preferences)
        try data.write(to: preferencesFileURL, options: .atomic)

        DispatchQueue.main.async {
            self.preferences = preferences
        }
    }

    func setDefaultAgent(_ agentID: UUID, forApp bundleID: String) throws {
        var prefs = preferences
        prefs.defaultAgentPerApp[bundleID] = agentID
        prefs.lastUsedAgentID = agentID
        try savePreferences(prefs)
    }

    func getDefaultAgent(forApp bundleID: String) -> UUID? {
        preferences.defaultAgentPerApp[bundleID] ?? preferences.lastUsedAgentID
    }

    func getCurrentAppBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
