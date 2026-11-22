import Foundation

nonisolated struct DoOnDate: Codable, Equatable, Sendable {
    let date: Date

    init(_ date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(Date.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date)
    }
}
