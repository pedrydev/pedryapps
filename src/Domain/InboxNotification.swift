import Foundation

nonisolated enum NotificationType: String, Codable {
    case information
    case attentionRequest

    var label: String {
        switch self {
        case .information: "Information"
        case .attentionRequest: "Attention request"
        }
    }

    var isEmphasized: Bool { self == .attentionRequest }
}

nonisolated enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case information
    case attentionRequest

    var id: Self { self }

    var label: String {
        switch self {
        case .all: "All"
        case .information: NotificationType.information.label
        case .attentionRequest: NotificationType.attentionRequest.label
        }
    }

    func applied(to notifications: [InboxNotification]) -> [InboxNotification] {
        switch self {
        case .all:
            notifications
        case .information:
            notifications.filter { $0.type == .information }
        case .attentionRequest:
            notifications.filter { $0.type == .attentionRequest }
        }
    }
}

nonisolated struct NotificationQuery: Equatable {
    var type: NotificationFilter = .all
    var searchText: String = ""

    func applied(to notifications: [InboxNotification]) -> [InboxNotification] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return type.applied(to: notifications).filter { notification in
            needle.isEmpty
                || notification.title.localizedCaseInsensitiveContains(needle)
                || notification.body.localizedCaseInsensitiveContains(needle)
        }
    }
}

nonisolated struct InboxNotification: Codable, Equatable, Identifiable {
    let id: UUID
    let source: MiniApp
    let type: NotificationType
    let title: String
    let body: String
    let postedAt: Date
    var isRead: Bool = false
}
