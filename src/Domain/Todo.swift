import Foundation

nonisolated struct Todo: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let categoryID: UUID
    var title: String
    var doOnDate: DoOnDate

    init(id: UUID = UUID(), categoryID: UUID, title: String, doOnDate: DoOnDate = DoOnDate()) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.doOnDate = doOnDate
    }

    static func hasText(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
