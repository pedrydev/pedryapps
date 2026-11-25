import SwiftUI

struct SettingsView: View {
    let todosSettingsStore: TodosSettingsStore
    let mcpSettingsStore: MCPSettingsStore
    let probedComponent: ProbedComponent

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
            DiagnosticsView(probedComponent: probedComponent)
                .tabItem {
                    Label("Diagnostics", systemImage: "heart.text.square")
                }
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
