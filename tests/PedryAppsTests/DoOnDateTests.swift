import Foundation
import Testing
@testable import PedryApps

struct DoOnDateTests {
    @Test(
        "Default is the next upcoming whole hour",
        arguments: [
            (hour: 8, minute: 30, expectedHour: 9),
            (hour: 9, minute: 0, expectedHour: 10),
            (hour: 15, minute: 10, expectedHour: 16),
        ]
    )
    func defaultIsNextUpcomingWholeHour(_ values: (hour: Int, minute: Int, expectedHour: Int)) throws {
        let calendar = utcCalendar()
        let now = try fixtureDate(2030, 1, 2, at: values.hour, minute: values.minute, calendar: calendar)
        let expected = try fixtureDate(2030, 1, 2, at: values.expectedHour, minute: 0, calendar: calendar)

        #expect(DoOnDate(now: now, calendar: calendar).date == expected)
    }

    @Test func preservesTimeWhenDecoded() throws {
        let calendar = utcCalendar()
        let afternoon = try fixtureDate(2030, 1, 2, at: 13, minute: 45, calendar: calendar)
        let data = try JSONEncoder().encode(afternoon)

        let doOnDate = try JSONDecoder().decode(DoOnDate.self, from: data)

        #expect(doOnDate.date == afternoon)
    }
}
