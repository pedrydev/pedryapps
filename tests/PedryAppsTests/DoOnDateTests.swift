import Foundation
import Testing
@testable import PedryApps

struct DoOnDateTests {
    @Test func normalizesDateWhenDecoded() throws {
        let calendar = Calendar.current
        let afternoon = try #require(
            calendar.date(from: DateComponents(year: 2030, month: 1, day: 2, hour: 13, minute: 45))
        )
        let data = try JSONEncoder().encode(afternoon)

        let doOnDate = try JSONDecoder().decode(DoOnDate.self, from: data)

        #expect(doOnDate.date == calendar.startOfDay(for: afternoon))
    }
}
