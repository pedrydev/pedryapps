import Foundation

nonisolated struct TodoDueNotificationRequest: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
}

nonisolated enum TodoNotificationAuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case unavailable
}
