import Foundation

struct Agent: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var backendURL: String
    var modelName: String
    var defaultPrompt: String
    var apiKey: String

    init(id: UUID = UUID(), name: String, backendURL: String, modelName: String = "gpt-4", defaultPrompt: String, apiKey: String) {
        self.id = id
        self.name = name
        self.backendURL = backendURL
        self.modelName = modelName
        self.defaultPrompt = defaultPrompt
        self.apiKey = apiKey
    }
}
