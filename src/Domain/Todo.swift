import Foundation

nonisolated struct Todo: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var doOnDate: DoOnDate

    init(id: UUID = UUID(), title: String, doOnDate: DoOnDate = DoOnDate()) {
        self.id = id
        self.title = title
        self.doOnDate = doOnDate
    }

    static func hasText(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
