import SwiftUI

struct NotConfiguredSettingsView: View {
    let miniApp: String

    var body: some View {
        ContentUnavailableView {
            Label("Not configured yet", systemImage: "wrench.and.screwdriver")
        } description: {
            Text("\(miniApp) settings are not available yet.")
        }
    }
}
