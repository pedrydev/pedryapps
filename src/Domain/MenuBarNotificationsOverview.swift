import Foundation

nonisolated enum NotificationRelativeAge {
    static func text(from postedAt: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(postedAt))
        guard seconds >= 60 else { return "just now" }
        let minutes = Int(seconds / 60)
        guard minutes >= 60 else { return "\(minutes)m ago" }
        let hours = minutes / 60
        guard hours >= 24 else { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

nonisolated struct MenuBarNotificationsOverview {
    struct Row {
        let source: String
        let title: String
        let relativeAge: String
    }

    let unreadCount: Int
    let unread: [Row]

    static func make(from notifications: [InboxNotification], now: Date = Date()) -> Self {
        let unreadNotifications = notifications.enumerated().filter { !$0.element.isRead }
        let newestFirst = unreadNotifications.sorted { lhs, rhs in
            if lhs.element.postedAt != rhs.element.postedAt {
                return lhs.element.postedAt > rhs.element.postedAt
            }
            return lhs.offset < rhs.offset
        }
        let rows = newestFirst.prefix(5).map { entry in
            Row(
                source: entry.element.source.name,
                title: entry.element.title,
                relativeAge: NotificationRelativeAge.text(from: entry.element.postedAt, now: now)
            )
        }
        return Self(unreadCount: unreadNotifications.count, unread: rows)
    }
}
