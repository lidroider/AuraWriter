import SwiftUI

struct AgentFormView: View {
    @ObservedObject var agentService: AgentService
    let mode: Mode

    @State private var name: String = ""
    @State private var backendURL: String = ""
    @State private var modelName: String = "gpt-4"
    @State private var defaultPrompt: String = ""
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var showingError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case add
        case edit(Agent)

        var title: String {
            switch self {
            case .add: return "Add Agent"
            case .edit: return "Edit Agent"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Backend URL", text: $backendURL)
                        .textContentType(.URL)
                    TextField("Model Name", text: $modelName)
                    HStack(spacing: 8) {
                        if showAPIKey {
                            TextField("API Key", text: $apiKey)
                                .textContentType(.password)
                        } else {
                            SecureField("API Key", text: $apiKey)
                                .textContentType(.password)
                        }

                        Button(action: {
                            showAPIKey.toggle()
                        }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Prompt")
                            .font(.headline)
                        TextEditor(text: $defaultPrompt)
                            .frame(minHeight: 200, maxHeight: 200)
                            .font(.body)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveAgent()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadAgent()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !backendURL.isEmpty && !defaultPrompt.isEmpty && !apiKey.isEmpty && !modelName.isEmpty
    }

    private func loadAgent() {
        if case .edit(let agent) = mode {
            name = agent.name
            backendURL = agent.backendURL
            modelName = agent.modelName
            defaultPrompt = agent.defaultPrompt
            apiKey = agent.apiKey ?? ""
        }
    }

    private func saveAgent() {
        // Validate URL format
        if !backendURL.hasPrefix("http://") && !backendURL.hasPrefix("https://") {
            errorMessage = "Backend URL must start with http:// or https://"
            showingError = true
            return
        }

        // Validate URL is valid
        guard URL(string: backendURL) != nil else {
            errorMessage = "Invalid backend URL format"
            showingError = true
            return
        }

        do {
            switch mode {
            case .add:
                let agent = Agent(
                    name: name,
                    backendURL: backendURL,
                    modelName: modelName,
                    defaultPrompt: defaultPrompt,
                    apiKey: apiKey
                )
                try agentService.addAgent(agent)
            case .edit(let existingAgent):
                var agent = existingAgent
                agent.name = name
                agent.backendURL = backendURL
                agent.modelName = modelName
                agent.defaultPrompt = defaultPrompt
                agent.apiKey = apiKey
                try agentService.updateAgent(agent)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
