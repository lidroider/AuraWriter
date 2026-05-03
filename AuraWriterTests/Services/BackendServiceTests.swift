import XCTest
@testable import AuraWriter

final class BackendServiceTests: XCTestCase {
    func testBuildRequestBody() throws {
        let agent = Agent(
            name: "Test Agent",
            backendURL: "https://api.example.com/v1/chat/completions",
            defaultPrompt: "Fix grammar",
            apiKey: "sk-test"
        )

        let service = BackendService()
        let body = try service.buildRequestBody(agent: agent, selectedText: "hello world")

        XCTAssertEqual(body["model"] as? String, "gpt-4")
        XCTAssertNotNil(body["messages"])
        let messages = body["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.count, 2)
        XCTAssertEqual(messages?[0]["role"], "system")
        XCTAssertEqual(messages?[0]["content"], "Fix grammar")
        XCTAssertEqual(messages?[1]["role"], "user")
        XCTAssertEqual(messages?[1]["content"], "hello world")
    }

    func testParseResponse() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Hello world."
                    }
                }
            ]
        }
        """

        let service = BackendService()
        let data = json.data(using: .utf8)!
        let result = try service.parseResponse(data)

        XCTAssertEqual(result, "Hello world.")
    }

    func testParseResponseMissingContent() throws {
        let json = """
        {
            "choices": []
        }
        """

        let service = BackendService()
        let data = json.data(using: .utf8)!

        XCTAssertThrowsError(try service.parseResponse(data)) { error in
            XCTAssertTrue(error is BackendError)
        }
    }

    func testBuildRequestBodyUsesAgentModelName() throws {
        let backendService = BackendService()
        let agent = Agent(
            name: "Test Agent",
            backendURL: "https://api.example.com",
            modelName: "gpt-4-turbo",
            defaultPrompt: "You are a helpful assistant",
            apiKey: "sk-test"
        )

        let body = try backendService.buildRequestBody(agent: agent, selectedText: "Hello")

        XCTAssertEqual(body["model"] as? String, "gpt-4-turbo")

        let messages = body["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.count, 2)
        XCTAssertEqual(messages?[0]["role"], "system")
        XCTAssertEqual(messages?[0]["content"], "You are a helpful assistant")
        XCTAssertEqual(messages?[1]["role"], "user")
        XCTAssertEqual(messages?[1]["content"], "Hello")
    }
}
