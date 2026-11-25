import SwiftUI

struct SettingsView: View {
    let todosSettingsStore: TodosSettingsStore
    let mcpSettingsStore: MCPSettingsStore
    let probeStore: DiagnosticsProbeStore
    @State private var isDiagnosticsExpanded = false

    var body: some View {
        TabView {
            TodosSettingsView(store: todosSettingsStore)
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle")
                }
            MCPSettingsView(store: mcpSettingsStore)
                .tabItem {
                    Label("MCP", systemImage: "network")
                }
            DiagnosticsView(
                probedComponent: probeStore.todos,
                isExpanded: $isDiagnosticsExpanded,
                onRefresh: probeStore.refresh
            )
            .tabItem {
                Label("Diagnostics", systemImage: "heart.text.square")
            }
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
