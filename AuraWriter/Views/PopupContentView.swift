import SwiftUI

struct PopupContentView: View {
    @ObservedObject var agentService: AgentService
    @ObservedObject var preferencesService: PreferencesService

    let selectedText: String
    let onRewrite: (Agent) -> Void
    let onCancel: () -> Void

    @State private var selectedAgent: Agent?
    @State private var isLoading = false

    private var resolvedAgent: Agent? {
        selectedAgent ?? getDefaultAgent()
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
                // Selected text preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Text")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(selectedText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 500) // ~30 lines at default font size
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
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
                    .onAppear {
                        if selectedAgent == nil {
                            selectedAgent = getDefaultAgent()
                        }
                    }
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
                                    onRewrite(agent)
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
                            .disabled(resolvedAgent == nil)
                            .opacity(resolvedAgent == nil ? 0.5 : 1.0)
                        }
                    }
                } else {
                    Text("No agents configured")
                        .foregroundColor(.secondary)
                    Button("Configure Agents") {
                        // This will be handled by AppDelegate
                        onCancel()
                    }
                }
            }
            .padding()
        }
        .frame(width: 800)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(20)
//        .shadow(radius: 20)
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
