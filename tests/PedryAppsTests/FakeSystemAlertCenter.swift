import Foundation
@testable import PedryApps

@MainActor
final class FakeSystemAlertCenter: SystemAlertCenter {
    var authorization: SystemAlertAuthorizationStatus = .authorized
    var authorizationAfterRequest: SystemAlertAuthorizationStatus = .authorized
    var authorizationRequests = 0
    var requests: [SystemAlertRequest] = []
    var addAttempts = 0
    var addError: Error?

    func authorizationStatus() async -> SystemAlertAuthorizationStatus { authorization }

    func requestAuthorization() async -> SystemAlertAuthorizationStatus {
        authorizationRequests += 1
        authorization = authorizationAfterRequest
        return authorization
    }

    func add(_ request: SystemAlertRequest) async throws {
        addAttempts += 1
        if let addError { throw addError }
        requests.append(request)
    }
}
