import Foundation
import Observation

@MainActor
@Observable
final class NotificationsStore: NotificationPosting {
    private(set) var notifications: [InboxNotification] = []

    private let documentStore: JSONDocumentStore<NotificationsDocument>?
    private let now: @MainActor () -> Date
    private let makeID: @MainActor () -> UUID

    init(
        documentStore: JSONDocumentStore<NotificationsDocument>? = nil,
        now: @escaping @MainActor () -> Date = { Date() },
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        self.documentStore = documentStore ?? (try? JSONDocumentStore(filename: "notifications.json"))
        self.now = now
        self.makeID = makeID
        if let document = try? self.documentStore?.load() {
            notifications = Self.newestFirst(document.notifications)
        }
    }

    func post(source: MiniApp, type: NotificationType, title: String, body: String) {
        let notification = InboxNotification(
            id: makeID(),
            source: source,
            type: type,
            title: title,
            body: body,
            postedAt: now()
        )
        var next = notifications
        next.append(notification)
        notifications = Self.newestFirst(next)
        persist(next)
    }

    private func persist(_ notifications: [InboxNotification]) {
        guard let documentStore else { return }
        try? documentStore.save(NotificationsDocument(notifications: notifications))
    }

    private static func newestFirst(_ notifications: [InboxNotification]) -> [InboxNotification] {
        notifications
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.postedAt != rhs.element.postedAt {
                    return lhs.element.postedAt > rhs.element.postedAt
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
