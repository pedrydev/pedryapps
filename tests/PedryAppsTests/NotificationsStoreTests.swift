import Foundation
import Testing

@testable import PedryApps

@MainActor
struct NotificationsStoreTests {
    @Test func postingGeneratesIdentifierAndPostedAtAndPersists() throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let identifier = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let store = makeStore(in: directory.url, now: postedAt, identifier: identifier)

        store.post(source: .todos, type: .information, title: "Time to work", body: "1 todo is ready to work")

        let notification = try #require(store.notifications.first)
        #expect(notification.id == identifier)
        #expect(notification.postedAt == postedAt)
        #expect(notification.source == .todos)
        #expect(notification.type == .information)
        #expect(notification.title == "Time to work")
        #expect(notification.body == "1 todo is ready to work")

        let reloaded = makeStore(in: directory.url, now: postedAt.addingTimeInterval(60), identifier: UUID())
        #expect(reloaded.notifications == [notification])
    }

    @Test func inboxListsNotificationsNewestFirst() throws {
        let directory = try TemporaryDirectory()
        let first = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let clock = MutableClock(now: first)
        let store = makeStore(in: directory.url, clock: clock)

        store.post(source: .todos, type: .information, title: "Older", body: "First")
        clock.now = first.addingTimeInterval(60)
        store.post(source: .todos, type: .attentionRequest, title: "Newer", body: "Second")

        #expect(store.notifications.map(\.title) == ["Newer", "Older"])
    }

    @Test func equalPostedAtKeepsInsertionOrder() throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json"),
            now: { postedAt }
        )

        store.post(source: .todos, type: .information, title: "First", body: "One")
        store.post(source: .todos, type: .attentionRequest, title: "Second", body: "Two")

        #expect(store.notifications.map(\.title) == ["First", "Second"])
    }

    @Test(
        "Reading a Notification marks it read regardless of type",
        arguments: [NotificationType.information, .attentionRequest]
    )
    func readingMarksNotificationRead(type: NotificationType) throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let store = makeStore(in: directory.url, now: postedAt, identifier: UUID())
        store.post(source: .todos, type: type, title: "Notification", body: "Body")
        let identifier = try #require(store.notifications.first?.id)
        #expect(store.unreadCount == 1)

        store.markRead(id: identifier)

        #expect(store.notifications.first?.isRead == true)
        #expect(store.unreadCount == 0)
        let reloaded = makeStore(in: directory.url, now: postedAt, identifier: UUID())
        #expect(reloaded.notifications.first?.isRead == true)
        #expect(reloaded.unreadCount == 0)
    }

    @Test func markAllReadClearsEveryNotificationIncludingAttentionRequests() throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let clock = MutableClock(now: postedAt)
        let store = makeStore(in: directory.url, clock: clock)
        store.post(source: .todos, type: .information, title: "Information", body: "Body")
        clock.now = postedAt.addingTimeInterval(60)
        store.post(source: .todos, type: .attentionRequest, title: "Attention", body: "Body")
        let firstIdentifier = try #require(store.notifications.first?.id)
        store.markRead(id: firstIdentifier)
        #expect(store.unreadCount == 1)

        store.markAllRead()

        #expect(store.notifications.allSatisfy { $0.isRead })
        #expect(store.unreadCount == 0)
        let reloaded = makeStore(in: directory.url, now: clock.now, identifier: UUID())
        #expect(reloaded.notifications.allSatisfy { $0.isRead })
        #expect(reloaded.unreadCount == 0)
    }

    @Test func expiredNotificationsArePurgedOnLaunchBeforeUnreadCount() throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let clock = MutableClock(now: postedAt)
        let seedingStore = makeStore(in: directory.url, clock: clock)
        seedingStore.post(source: .todos, type: .information, title: "Expired", body: "Body")
        clock.now = postedAt.addingTimeInterval(60)
        seedingStore.post(source: .todos, type: .attentionRequest, title: "Live", body: "Body")

        let launchDate = postedAt.addingTimeInterval(NotificationsStore.lifetime)
        let store = makeStore(in: directory.url, now: launchDate, identifier: UUID())

        #expect(store.notifications.map(\.title) == ["Live"])
        #expect(store.unreadCount == 1)
        let relaunched = makeStore(in: directory.url, now: launchDate, identifier: UUID())
        #expect(relaunched.notifications.map(\.title) == ["Live"])
        #expect(relaunched.unreadCount == 1)
    }

    @Test func runningExpiryRemovesNotificationAtSixHoursAfterPostedAt() throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let clock = MutableClock(now: postedAt)
        let scheduler = ExpiryScheduler()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json"),
            now: { clock.now },
            scheduleExpiry: scheduler.schedule
        )
        store.startExpiryScheduling()
        store.post(source: .todos, type: .information, title: "Notification", body: "Body")
        #expect(scheduler.delays == [NotificationsStore.lifetime])

        clock.now = postedAt.addingTimeInterval(NotificationsStore.lifetime - 1)
        scheduler.fire()
        #expect(store.notifications.map(\.title) == ["Notification"])

        clock.now = postedAt.addingTimeInterval(NotificationsStore.lifetime)
        scheduler.fire()
        #expect(store.notifications.isEmpty)
        #expect(store.unreadCount == 0)
        let relaunched = makeStore(in: directory.url, now: clock.now, identifier: UUID())
        #expect(relaunched.notifications.isEmpty)
    }

    private func makeStore(in directory: URL, clock: MutableClock) -> NotificationsStore {
        NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "notifications.json"),
            now: { clock.now }
        )
    }

    private func makeStore(in directory: URL, now: Date, identifier: UUID) -> NotificationsStore {
        NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "notifications.json"),
            now: { now },
            makeID: { identifier }
        )
    }
}

@MainActor
private final class MutableClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

@MainActor
private final class ExpiryScheduler {
    var delays: [TimeInterval] = []
    private var action: (@MainActor () -> Void)?

    func schedule(delay: TimeInterval, action: @escaping @MainActor () -> Void) -> NotificationExpiryCancellable {
        delays.append(delay)
        self.action = action
        return NotificationExpiryCancellable {}
    }

    func fire() {
        action?()
    }
}
