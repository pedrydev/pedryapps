import SwiftUI

struct SettingsView: View {
    let todosSettingsStore: TodosSettingsStore
    let mcpSettingsStore: MCPSettingsStore

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
            DiagnosticsView()
                .tabItem {
                    Label("Diagnostics", systemImage: "heart.text.square")
                }
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
