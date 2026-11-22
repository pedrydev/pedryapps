import SwiftUI

@main
struct MacosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    HotkeyManager.shared.register(.showWindow) {
                        NSApp.activate(ignoringOtherApps: true)
                        (NSApp.keyWindow ?? NSApp.windows.first)?.makeKeyAndOrderFront(nil)
                    }
                }
        }
    }
}
