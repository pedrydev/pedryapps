import Foundation

@MainActor
protocol TodoDueNotificationCenter: AnyObject {
    func authorizationStatus() async -> TodoNotificationAuthorizationStatus
    func requestAuthorization() async -> TodoNotificationAuthorizationStatus
    func add(_ request: TodoDueNotificationRequest) async throws
}
