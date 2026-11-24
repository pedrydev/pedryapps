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
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json"),
            now: { clock.now }
        )

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
