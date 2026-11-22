import Foundation
import Testing

nonisolated func utcCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

nonisolated func fixtureDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    at hour: Int,
    minute: Int,
    second: Int = 0,
    calendar: Calendar
) throws -> Date {
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    return try #require(calendar.date(from: components))
}
