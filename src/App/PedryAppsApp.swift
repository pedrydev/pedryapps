import AppKit
import SwiftUI

@main
struct PedryAppsApp: App {
    @NSApplicationDelegateAdaptor(MenuBarAppDelegate.self) private var appDelegate

    init() {
        HotkeyManager.shared.register(.showWindow) {
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: appDelegate.store)
                .background {
                    OpenWindowRegistrar { appDelegate.registerOpenWindow($0) }
                }
        }

        Settings {
            SettingsView()
        }
    }
}

private struct OpenWindowRegistrar: View {
    @Environment(\.openWindow) private var openWindow

    let register: (OpenWindowAction) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear { register(openWindow) }
    }
}
