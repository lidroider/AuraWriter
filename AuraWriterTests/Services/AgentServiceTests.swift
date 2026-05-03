import XCTest
@testable import AuraWriter

final class AgentServiceTests: XCTestCase {
    var tempDirectory: URL!
    var agentService: AgentService!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        agentService = AgentService(storageDirectory: tempDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testLoadAgentsFromEmptyFile() throws {
        let agents = try agentService.loadAgents()
        XCTAssertEqual(agents.count, 0)
    }

    func testSaveAndLoadAgents() throws {
        let agent = Agent(
            name: "Test Agent",
            backendURL: "https://api.example.com/v1/chat/completions",
            modelName: "gpt-4",
            defaultPrompt: "Test prompt",
            apiKey: "sk-test"
        )

        try agentService.saveAgents([agent])
        let loaded = try agentService.loadAgents()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].name, agent.name)
        XCTAssertEqual(loaded[0].backendURL, agent.backendURL)
        XCTAssertEqual(loaded[0].modelName, agent.modelName)
        XCTAssertEqual(loaded[0].apiKey, agent.apiKey)
    }

    func testAddAgent() throws {
        let agent = Agent(
            name: "New Agent",
            backendURL: "https://api.example.com",
            defaultPrompt: "Test",
            apiKey: "sk-test"
        )

        try agentService.addAgent(agent)
        let loaded = try agentService.loadAgents()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, agent.id)
    }

    func testUpdateAgent() throws {
        var agent = Agent(
            name: "Original Name",
            backendURL: "https://api.example.com",
            defaultPrompt: "Test",
            apiKey: "sk-test"
        )

        try agentService.addAgent(agent)

        agent.name = "Updated Name"
        agent.modelName = "gpt-4-turbo"
        try agentService.updateAgent(agent)

        let loaded = try agentService.loadAgents()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].name, "Updated Name")
        XCTAssertEqual(loaded[0].modelName, "gpt-4-turbo")
    }

    func testDeleteAgent() throws {
        let agent1 = Agent(
            name: "Agent 1",
            backendURL: "https://api.example.com",
            defaultPrompt: "Test",
            apiKey: "sk-test1"
        )
        let agent2 = Agent(
            name: "Agent 2",
            backendURL: "https://api.example.com",
            defaultPrompt: "Test",
            apiKey: "sk-test2"
        )

        try agentService.addAgent(agent1)
        try agentService.addAgent(agent2)

        try agentService.deleteAgent(agent1)

        let loaded = try agentService.loadAgents()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, agent2.id)
    }
}
