import Foundation

nonisolated struct NotificationsDocument: Codable {
    var notifications: [InboxNotification] = []
}
