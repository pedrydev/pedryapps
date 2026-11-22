import Testing
import UserNotifications
@testable import PedryApps

@MainActor
struct MenuBarAppDelegateNotificationTests {
    @Test func notificationResponseOpensMainWindow() {
        let delegate = MenuBarAppDelegate()
        var openedId: String?
        delegate.registerOpenMainWindowHandler { openedId = $0 }

        delegate.handleNotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier)

        #expect(openedId == "main")
    }

    @Test func nonDefaultActionDoesNotOpenMainWindow() {
        let delegate = MenuBarAppDelegate()
        var openedId: String?
        delegate.registerOpenMainWindowHandler { openedId = $0 }

        delegate.handleNotificationResponse(actionIdentifier: UNNotificationDismissActionIdentifier)

        #expect(openedId == nil)
    }
}
