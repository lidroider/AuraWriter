import SwiftUI

struct AgentListView: View {
    @ObservedObject var agentService: AgentService
    @State private var selectedAgent: Agent?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Agents")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Agent List
            if agentService.agents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No agents configured")
                        .font(.headline)
                    Text("Add an agent to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedAgent) {
                    ForEach(agentService.agents) { agent in
                        AgentRow(agent: agent)
                            .tag(agent)
                            .contextMenu {
                                Button("Edit") {
                                    selectedAgent = agent
                                    showingEditSheet = true
                                }
                                Button("Delete", role: .destructive) {
                                    deleteAgent(agent)
                                }
                            }
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showingAddSheet) {
            AgentFormView(agentService: agentService, mode: .add)
        }
        .sheet(isPresented: $showingEditSheet) {
            if let agent = selectedAgent {
                AgentFormView(agentService: agentService, mode: .edit(agent))
            }
        }
    }

    private func deleteAgent(_ agent: Agent) {
        try? agentService.deleteAgent(agent)
    }
}

struct AgentRow: View {
    let agent: Agent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(agent.name)
                .font(.headline)
            Text(agent.backendURL)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
