import Foundation
import UserNotifications

@MainActor
final class SystemTodoDueNotificationCenter: TodoDueNotificationCenter {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> TodoNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return Self.status(from: settings.authorizationStatus)
    }

    func requestAuthorization() async -> TodoNotificationAuthorizationStatus {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .unavailable
        }
    }

    func add(_ request: TodoDueNotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: nil
        )
        try await center.add(notificationRequest)
    }

    private static func status(from status: UNAuthorizationStatus) -> TodoNotificationAuthorizationStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        @unknown default:
            return .unavailable
        }
    }
}
