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
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
