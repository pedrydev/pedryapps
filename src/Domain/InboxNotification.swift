import Foundation

enum NotificationType: String, Codable {
    case information
    case attentionRequest
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
