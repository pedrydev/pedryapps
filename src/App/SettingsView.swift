import SwiftUI

struct SettingsView: View {
    let todosSettingsStore: TodosSettingsStore

    var body: some View {
        TabView {
            TodosSettingsView(store: todosSettingsStore)
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle")
                }
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
