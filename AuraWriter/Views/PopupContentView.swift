import SwiftUI

struct PopupContentView: View {
    @ObservedObject var agentService: AgentService
    @ObservedObject var preferencesService: PreferencesService

    let selectedText: String
    let onRewrite: (Agent, String) -> Void  // Updated signature to pass edited text
    let onCancel: () -> Void

    @State private var selectedAgent: Agent?
    @State private var isLoading = false
    @State private var editableText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var resolvedAgent: Agent? {
        selectedAgent ?? getDefaultAgent()
    }

    private var isRewriteDisabled: Bool {
        editableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AuraWriter - Rewrite Text")
                    .font(.headline)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            VStack(spacing: 16) {
                // Editable text input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text to Rewrite")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if editableText.isEmpty {
                            Text("Enter text to translate...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $editableText)
                            .font(.body)
                            .frame(maxHeight: 500)
                            .focused($isTextFieldFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                    }
                    .frame(maxHeight: 500)
                }

                // Agent selection
                if !agentService.agents.isEmpty {
                    Picker("Agent:", selection: Binding(
                        get: { resolvedAgent ?? agentService.agents[0] },
                        set: { selectedAgent = $0 }
                    )) {
                        ForEach(agentService.agents) { agent in
                            Text(agent.name).tag(agent)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: agentService.agents) { _ in
                        if selectedAgent == nil {
                            selectedAgent = getDefaultAgent()
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .keyboardShortcut(.cancelAction)

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                                Text("Rewriting...")
                            }
                            .frame(minWidth: 80)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        } else {
                            Button {
                                isLoading = true
                                if let agent = resolvedAgent {
                                    onRewrite(agent, editableText)
                                }
                            } label: {
                                Text("Rewrite")
                                    .foregroundColor(.white)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor)
                            )
                            .keyboardShortcut(.defaultAction)
                            .disabled(isRewriteDisabled)
                            .opacity(isRewriteDisabled ? 0.5 : 1.0)
                        }
                    }
                } else {
                    Text("No agents configured")
                        .foregroundColor(.secondary)
                    Button("Configure Agents") {
                        onCancel()
                    }
                }
            }
            .padding()
        }
        .frame(width: 800)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(20)
        .onAppear {
            // Initialize editable text with selected text (or empty)
            editableText = selectedText

            // Set default agent if none selected
            if selectedAgent == nil {
                selectedAgent = getDefaultAgent()
            }

            // Auto-focus the text editor
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    private func getDefaultAgent() -> Agent? {
        if let bundleID = preferencesService.getCurrentAppBundleID(),
           let agentID = preferencesService.getDefaultAgent(forApp: bundleID),
           let agent = agentService.agents.first(where: { $0.id == agentID }) {
            return agent
        }
        return agentService.agents.first
    }
}
