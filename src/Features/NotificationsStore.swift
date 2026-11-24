import Foundation
import Observation

@MainActor
struct NotificationExpiryCancellable {
    let cancel: @MainActor () -> Void
}

@MainActor
@Observable
final class NotificationsStore: NotificationPosting {
    private(set) var notifications: [InboxNotification] = []

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    static let lifetime: TimeInterval = 6 * 60 * 60

    private let documentStore: JSONDocumentStore<NotificationsDocument>?
    private let now: @MainActor () -> Date
    private let makeID: @MainActor () -> UUID
    private let scheduleExpiry:
        @MainActor (
            TimeInterval,
            @escaping @MainActor () -> Void
        ) -> NotificationExpiryCancellable

    private var expiryTask: NotificationExpiryCancellable?
    private var isExpiryScheduling = false

    init(
        documentStore: JSONDocumentStore<NotificationsDocument>? = nil,
        now: @escaping @MainActor () -> Date = { Date() },
        makeID: @escaping @MainActor () -> UUID = { UUID() },
        scheduleExpiry:
            @escaping @MainActor (
                TimeInterval,
                @escaping @MainActor () -> Void
            ) -> NotificationExpiryCancellable = NotificationsStore.scheduleExpiry
    ) {
        self.documentStore = documentStore ?? (try? JSONDocumentStore(filename: "notifications.json"))
        self.now = now
        self.makeID = makeID
        self.scheduleExpiry = scheduleExpiry
        if let document = try? self.documentStore?.load() {
            notifications = Self.newestFirst(document.notifications)
        }
        purgeExpired()
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
        replaceNotifications(with: Self.newestFirst(next))
        scheduleNextExpiry()
    }

    func markRead(id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }),
            !notifications[index].isRead
        else { return }
        var next = notifications
        next[index].isRead = true
        replaceNotifications(with: next)
    }

    func markAllRead() {
        guard notifications.contains(where: { !$0.isRead }) else { return }
        var next = notifications
        for index in next.indices {
            next[index].isRead = true
        }
        replaceNotifications(with: next)
    }

    func purgeExpired() {
        let current = now()
        let next = notifications.filter { current < $0.postedAt.addingTimeInterval(Self.lifetime) }
        if next.count != notifications.count {
            replaceNotifications(with: next)
        }
        scheduleNextExpiry()
    }

    func startExpiryScheduling() {
        guard !isExpiryScheduling else { return }
        isExpiryScheduling = true
        scheduleNextExpiry()
    }

    private func scheduleNextExpiry() {
        expiryTask?.cancel()
        expiryTask = nil
        guard isExpiryScheduling,
            let soonestExpiry = notifications.map({ $0.postedAt.addingTimeInterval(Self.lifetime) }).min()
        else { return }
        let delay = max(0, soonestExpiry.timeIntervalSince(now()))
        expiryTask = scheduleExpiry(delay) { [weak self] in
            self?.purgeExpired()
        }
    }

    private static func scheduleExpiry(
        delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> NotificationExpiryCancellable {
        let timer = Timer(timeInterval: delay, repeats: false) { _ in
            MainActor.assumeIsolated { action() }
        }
        RunLoop.current.add(timer, forMode: .common)
        return NotificationExpiryCancellable { timer.invalidate() }
    }

    private func replaceNotifications(with next: [InboxNotification]) {
        notifications = next
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
