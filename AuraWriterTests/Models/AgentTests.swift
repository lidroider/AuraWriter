import XCTest
@testable import AuraWriter

final class AgentTests: XCTestCase {
    func testAgentCodable() throws {
        let agent = Agent(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            name: "Test Agent",
            backendURL: "https://api.example.com/v1/chat/completions",
            modelName: "gpt-4",
            defaultPrompt: "Test prompt",
            apiKey: "sk-test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(agent)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Agent.self, from: data)

        XCTAssertEqual(decoded.id, agent.id)
        XCTAssertEqual(decoded.name, agent.name)
        XCTAssertEqual(decoded.backendURL, agent.backendURL)
        XCTAssertEqual(decoded.modelName, agent.modelName)
        XCTAssertEqual(decoded.defaultPrompt, agent.defaultPrompt)
        XCTAssertEqual(decoded.apiKey, agent.apiKey)
    }

    func testAgentGeneratesUUIDByDefault() {
        let agent1 = Agent(
            name: "Agent 1",
            backendURL: "https://api.example.com",
            defaultPrompt: "Prompt",
            apiKey: "sk-test1"
        )

        let agent2 = Agent(
            name: "Agent 2",
            backendURL: "https://api.example.com",
            defaultPrompt: "Prompt",
            apiKey: "sk-test2"
        )

        XCTAssertNotEqual(agent1.id, agent2.id)
    }

    func testAgentWithModelName() throws {
        let agent = Agent(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            name: "Test Agent",
            backendURL: "https://api.example.com/v1/chat/completions",
            modelName: "gpt-4-turbo",
            defaultPrompt: "Test prompt",
            apiKey: "sk-test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(agent)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Agent.self, from: data)

        XCTAssertEqual(decoded.modelName, "gpt-4-turbo")
        XCTAssertEqual(decoded.apiKey, "sk-test")
    }
}
