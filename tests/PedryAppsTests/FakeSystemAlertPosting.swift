import Foundation
@testable import PedryApps

@MainActor
final class FakeSystemAlertPosting: SystemAlertPosting {
    private(set) var posts: [SystemAlertRequest] = []

    func post(_ request: SystemAlertRequest) async {
        posts.append(request)
    }
}
