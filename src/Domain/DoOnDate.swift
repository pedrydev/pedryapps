import Foundation

nonisolated struct DoOnDate: Codable, Equatable, Sendable {
    let date: Date

    var isUpcoming: Bool { date > Date() }

    init(_ date: Date) {
        self.date = date
    }

    init(now: Date = Date(), calendar: Calendar = .current) {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 9
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        if let nine = calendar.date(from: components), nine > now {
            self.date = nine
        } else {
            self.date = calendar.dateInterval(of: .hour, for: now)?.end ?? now.addingTimeInterval(3600)
        }
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
