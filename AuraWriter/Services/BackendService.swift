import Foundation

enum BackendError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response format from backend"
        case .emptyResponse:
            return "Backend returned empty response"
        case .timeout:
            return "Request timed out after 30 seconds"
        }
    }
}

class BackendService {
    private let timeout: TimeInterval = 30.0

    func rewriteText(agent: Agent, selectedText: String) async throws -> String {
        guard let url = URL(string: agent.backendURL) else {
            throw BackendError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.setValue("Bearer \(agent.apiKey)", forHTTPHeaderField: "Authorization")

        let body = try buildRequestBody(agent: agent, selectedText: selectedText)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw BackendError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode))
            }

            return try parseResponse(data)
        } catch let error as BackendError {
            throw error
        } catch {
            throw BackendError.networkError(error)
        }
    }

    func buildRequestBody(agent: Agent, selectedText: String) throws -> [String: Any] {
        return [
            "model": agent.modelName,
            "messages": [
                [
                    "role": "user",
                    "content": "\(agent.defaultPrompt)\n\(selectedText)"
                ]
            ]
        ]
    }

    func parseResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            throw BackendError.emptyResponse
        }

        return content
    }
}
