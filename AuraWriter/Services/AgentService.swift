import Foundation
import Combine

class AgentService: ObservableObject {
    @Published var agents: [Agent] = []

    private let storageDirectory: URL
    private let agentsFileName = "agents.json"
    private var fileMonitor: DispatchSourceFileSystemObject?

    init(storageDirectory: URL? = nil) {
        if let directory = storageDirectory {
            self.storageDirectory = directory
        } else {
            self.storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("AuraWriter")
        }

        createStorageDirectoryIfNeeded()
        loadAgentsFromDisk()
        startFileWatching()
    }

    deinit {
        stopFileWatching()
    }

    private var agentsFileURL: URL {
        storageDirectory.appendingPathComponent(agentsFileName)
    }

    private func createStorageDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    func loadAgents() throws -> [Agent] {
        guard FileManager.default.fileExists(atPath: agentsFileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: agentsFileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([Agent].self, from: data)
    }

    func saveAgents(_ agents: [Agent]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(agents)
        try data.write(to: agentsFileURL, options: .atomic)

        DispatchQueue.main.async {
            self.agents = agents
        }
    }

    private func loadAgentsFromDisk() {
        do {
            agents = try loadAgents()
        } catch {
            print("Failed to load agents: \(error)")
            agents = []
        }
    }

    private func startFileWatching() {
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: agentsFileURL.path) {
            try? Data("[]".utf8).write(to: agentsFileURL)
        }

        let fileDescriptor = open(agentsFileURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global()
        )

        source.setEventHandler { [weak self] in
            self?.loadAgentsFromDisk()
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }

        source.resume()
        fileMonitor = source
    }

    private func stopFileWatching() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }

    func addAgent(_ agent: Agent) throws {
        var currentAgents = try loadAgents()
        currentAgents.append(agent)
        try saveAgents(currentAgents)
    }

    func updateAgent(_ agent: Agent) throws {
        var currentAgents = try loadAgents()
        if let index = currentAgents.firstIndex(where: { $0.id == agent.id }) {
            currentAgents[index] = agent
            try saveAgents(currentAgents)
        }
    }

    func deleteAgent(_ agent: Agent) throws {
        var currentAgents = try loadAgents()
        currentAgents.removeAll { $0.id == agent.id }
        try saveAgents(currentAgents)
    }
}
