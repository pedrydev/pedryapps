import Foundation
import UserNotifications

nonisolated struct SystemAlertRequest: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
}

nonisolated enum SystemAlertAuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

@MainActor
protocol SystemAlertCenter: AnyObject {
    func authorizationStatus() async -> SystemAlertAuthorizationStatus
    func requestAuthorization() async -> SystemAlertAuthorizationStatus
    func add(_ request: SystemAlertRequest) async throws
}

@MainActor
final class SystemUserNotificationCenter: SystemAlertCenter {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> SystemAlertAuthorizationStatus {
        let settings = await center.notificationSettings()
        return Self.status(from: settings.authorizationStatus)
    }

    func requestAuthorization() async -> SystemAlertAuthorizationStatus {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .unavailable
        }
    }

    func add(_ request: SystemAlertRequest) async throws {
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

    private static func status(from status: UNAuthorizationStatus) -> SystemAlertAuthorizationStatus {
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

@MainActor
protocol SystemAlertPosting: AnyObject {
    func post(identifier: String, title: String, body: String) async
}

@MainActor
final class SystemAlertPoster: SystemAlertPosting {
    private let center: any SystemAlertCenter

    init(center: any SystemAlertCenter = SystemUserNotificationCenter()) {
        self.center = center
    }

    func post(identifier: String, title: String, body: String) async {
        let status = await center.authorizationStatus()
        let resolved: SystemAlertAuthorizationStatus
        if status == .notDetermined {
            resolved = await center.requestAuthorization()
        } else {
            resolved = status
        }
        guard resolved == .authorized else { return }
        let request = SystemAlertRequest(identifier: identifier, title: title, body: body)
        try? await center.add(request)
    }
}
