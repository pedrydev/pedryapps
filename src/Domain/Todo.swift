import Foundation

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var doOnDate: Date

    init(id: UUID = UUID(), title: String, doOnDate: Date = Date()) {
        self.id = id
        self.title = title
        self.doOnDate = Calendar.current.startOfDay(for: doOnDate)
    }
}
