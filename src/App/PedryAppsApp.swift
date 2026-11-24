import AppKit
import SwiftUI

@main
struct PedryAppsApp: App {
    @NSApplicationDelegateAdaptor(MenuBarAppDelegate.self) private var appDelegate

    private var todosSettingsStore: TodosSettingsStore { appDelegate.todosSettingsStore }

    init() {
        HotkeyManager.shared.register(.showWindow) {
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(
                store: appDelegate.store,
                shouldEnterFullScreen: appDelegate.consumeFullScreenRequest
            )
            .background {
                AppActionRegistrar(
                    registerWindow: appDelegate.registerOpenMainWindowHandler,
                    registerSettings: appDelegate.registerOpenSettings
                )
            }
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Todos") {
                Button("Add Todo") {
                    NSApp.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(name: .focusNewTodo, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Check Off Selected") {
                    NotificationCenter.default.post(name: .checkOffSelectedTodos, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }

        Settings {
            SettingsView(todosSettingsStore: todosSettingsStore)
        }
    }
}

private struct AppActionRegistrar: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    let registerWindow: (@escaping (String) -> Void) -> Void
    let registerSettings: (OpenSettingsAction) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                registerWindow { id in
                    if let mainWindow = NSApp.windows.first(where: { $0.identifier == .mainWindow }) {
                        mainWindow.makeKeyAndOrderFront(nil)
                    } else {
                        openWindow(id: id)
                    }
                }
                registerSettings(openSettings)
            }
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
    static let focusNewTodo = Notification.Name("focusNewTodo")
    static let checkOffSelectedTodos = Notification.Name("checkOffSelectedTodos")
}
