import SwiftUI

@main
struct PedryAppsApp: App {
    @State private var store = TodosStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onAppear {
                    HotkeyManager.shared.register(.showWindow) {
                        NSApp.activate(ignoringOtherApps: true)
                        (NSApp.keyWindow ?? NSApp.windows.first)?.makeKeyAndOrderFront(nil)
                    }
                }
        }
    }
}
