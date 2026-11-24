import Foundation
import Testing

@testable import PedryApps

@MainActor
struct MiniAppSelectionStoreTests {
    @Test func firstLaunchSelectsTodos() {
        withIsolatedDefaults { defaults in
            let store = MiniAppSelectionStore(userDefaults: defaults)

            #expect(store.selected == .todos)
        }
    }

    @Test func selectionIsRestoredOnRelaunch() {
        withIsolatedDefaults { defaults in
            let selectable: Set<MiniApp> = [.todos, .notifications]
            let store = MiniAppSelectionStore(userDefaults: defaults, selectableMiniApps: selectable)

            store.select(.notifications)

            let reloaded = MiniAppSelectionStore(userDefaults: defaults, selectableMiniApps: selectable)
            #expect(reloaded.selected == .notifications)
        }
    }

    @Test func unavailableMiniAppsCannotBeSelected() {
        withIsolatedDefaults { defaults in
            let store = MiniAppSelectionStore(userDefaults: defaults)

            store.select(.notifications)
            store.select(.calendar)

            #expect(store.selected == .todos)
        }
    }

    @Test func storedUnavailableSelectionFallsBackToTodos() {
        withIsolatedDefaults { defaults in
            let storeWithNotifications = MiniAppSelectionStore(
                userDefaults: defaults,
                selectableMiniApps: [.todos, .notifications]
            )
            storeWithNotifications.select(.notifications)

            let store = MiniAppSelectionStore(userDefaults: defaults)

            #expect(store.selected == .todos)
        }
    }

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let name = "PedryAppsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }
}
