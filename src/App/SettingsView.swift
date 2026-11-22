import SwiftUI

struct SettingsView: View {
    let todosSettingsStore: TodosSettingsStore

    var body: some View {
        TabView {
            TodosSettingsView(store: todosSettingsStore)
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle")
                }

            NotConfiguredSettingsView(miniApp: "Notifications")
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            NotConfiguredSettingsView(miniApp: "Calendar")
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
        .frame(minWidth: 380, minHeight: 220)
    }
}
