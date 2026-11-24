import Foundation
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

    @Test func openingNotificationsDoesNotChangeReadState() throws {
        let suiteName = "MenuBarNotifications.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let directory = try TemporaryDirectory()
        let delegate = MenuBarAppDelegate(
            selectionStore: MiniAppSelectionStore(userDefaults: defaults),
            notificationsStore: NotificationsStore(
                documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
            )
        )
        delegate.notificationsStore.post(source: .todos, type: .information, title: "Due", body: "Body")

        delegate.openNotificationsFromMenuBar()

        #expect(delegate.miniAppSelectionStore.selected == .notifications)
        #expect(delegate.notificationsStore.notifications.allSatisfy { !$0.isRead })
    }
}

struct MenuBarNotificationsOverviewTests {
    private let baseDate = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func unreadCountIncludesEveryUnreadNotification() {
        let notifications =
            (0..<12)
            .map { index in
                notification(title: "Unread \(index)", minutesAgo: index)
            }
            + [notification(title: "Read", minutesAgo: 0, isRead: true)]

        let overview = MenuBarNotificationsOverview.make(from: notifications, now: baseDate)

        #expect(overview.unreadCount == 12)
    }

    @Test func dropdownUsesFiveNewestUnreadNotifications() {
        let unread = (1...7).map { index in
            notification(title: "Unread \(index)", minutesAgo: index)
        }
        let read = notification(title: "Read", minutesAgo: 0, isRead: true)
        let now = baseDate.addingTimeInterval(-60)

        let overview = MenuBarNotificationsOverview.make(from: [read] + unread, now: now)

        #expect(overview.unread.map(\.title) == ["Unread 1", "Unread 2", "Unread 3", "Unread 4", "Unread 5"])
        #expect(overview.unread.map(\.source) == Array(repeating: "Todos", count: 5))
        #expect(overview.unread.map(\.relativeAge) == ["just now", "1m ago", "2m ago", "3m ago", "4m ago"])
    }

    @Test func emptyInboxHasNoUnreadRows() {
        let overview = MenuBarNotificationsOverview.make(from: [], now: baseDate)

        #expect(overview.unreadCount == 0)
        #expect(overview.unread.isEmpty)
    }

    @Test(
        "Relative age is compact",
        arguments: [
            (seconds: 0.0, expected: "just now"),
            (seconds: 30.0, expected: "just now"),
            (seconds: 90.0, expected: "1m ago"),
            (seconds: 7_200.0, expected: "2h ago"),
            (seconds: 172_800.0, expected: "2d ago"),
        ]
    )
    func relativeAgeIsCompact(_ values: (seconds: TimeInterval, expected: String)) {
        let postedAt = baseDate.addingTimeInterval(-values.seconds)

        #expect(NotificationRelativeAge.text(from: postedAt, now: baseDate) == values.expected)
    }

    private func notification(title: String, minutesAgo: Int, isRead: Bool = false) -> InboxNotification {
        InboxNotification(
            id: UUID(),
            source: .todos,
            type: .information,
            title: title,
            body: "Body",
            postedAt: baseDate.addingTimeInterval(-Double(minutesAgo) * 60),
            isRead: isRead
        )
    }
}
