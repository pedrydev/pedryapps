import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            TodosSettingsView()
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
        .frame(width: 440, height: 260)
    }
}
