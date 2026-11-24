import Foundation
import Testing

@testable import PedryApps

struct TodosOverviewTests {
    @Test func selectsOnlyTodaysUpcomingTodos() throws {
        let calendar = utcCalendar()
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: calendar)
        let passed = Todo(
            categoryID: UUID(), title: "Passed", doOnDate: DoOnDate(try fixtureDate(2030, 1, 2, at: 9, minute: 0, calendar: calendar)))
        let upcoming = Todo(
            categoryID: UUID(), title: "Upcoming", doOnDate: DoOnDate(try fixtureDate(2030, 1, 2, at: 11, minute: 0, calendar: calendar)))
        let tomorrow = Todo(
            categoryID: UUID(), title: "Tomorrow", doOnDate: DoOnDate(try fixtureDate(2030, 1, 3, at: 11, minute: 0, calendar: calendar)))

        let overview = TodosOverview.make(from: [passed, upcoming, tomorrow], calendar: calendar, now: now)

        #expect(overview.items.map(\.title) == ["Upcoming"])
        #expect(overview.additionalCount == 0)
    }

    @Test func ordersByDoOnDateThenCategoryThenWithinCategory() throws {
        let calendar = utcCalendar()
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: calendar)
        let work = Category(name: "Work")
        let home = Category(name: "Home")
        let categories = [work, home]
        let sameTime = try fixtureDate(2030, 1, 2, at: 11, minute: 0, calendar: calendar)
        let later = try fixtureDate(2030, 1, 2, at: 12, minute: 0, calendar: calendar)
        let todos = [
            Todo(categoryID: home.id, title: "Home second", doOnDate: DoOnDate(sameTime)),
            Todo(categoryID: work.id, title: "Work first", doOnDate: DoOnDate(sameTime)),
            Todo(categoryID: home.id, title: "Home first", doOnDate: DoOnDate(later)),
            Todo(categoryID: work.id, title: "Work later", doOnDate: DoOnDate(later)),
        ]

        let overview = TodosOverview.make(from: todos, categories: categories, calendar: calendar, now: now)

        #expect(overview.items.map(\.title) == ["Work first", "Home second", "Work later", "Home first"])
    }

    @Test func ordersByTimeLeftWithManualTieBreakAndLimitsToFive() throws {
        let calendar = utcCalendar()
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: calendar)
        let category = Category(name: "Work")
        let todos = try [
            todo("A", at: 12, calendar: calendar, categoryID: category.id),
            todo("B", at: 11, calendar: calendar, categoryID: category.id),
            todo("C", at: 11, calendar: calendar, categoryID: category.id),
            todo("D", at: 13, calendar: calendar, categoryID: category.id),
            todo("E", at: 14, calendar: calendar, categoryID: category.id),
            todo("F", at: 15, calendar: calendar, categoryID: category.id),
            todo("G", at: 16, calendar: calendar, categoryID: category.id),
        ]

        let overview = TodosOverview.make(from: todos, categories: [category], calendar: calendar, now: now)

        #expect(overview.items.map(\.title) == ["B", "C", "A", "D", "E"])
        #expect(overview.additionalCount == 2)
    }

    @Test(
        "Formats time left compactly",
        arguments: [
            (seconds: 8_100.0, expected: "in 2h 15m"),
            (seconds: 7_200.0, expected: "in 2h"),
            (seconds: 2_700.0, expected: "in 45m"),
            (seconds: 30.0, expected: "now"),
        ]
    )
    func formatsTimeLeftCompactly(_ values: (seconds: TimeInterval, expected: String)) {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let deadline = now.addingTimeInterval(values.seconds)

        #expect(TimeLeftLabel.text(from: now, to: deadline) == values.expected)
    }

    private func todo(_ title: String, at hour: Int, calendar: Calendar, categoryID: UUID = UUID()) throws -> Todo {
        Todo(
            categoryID: categoryID,
            title: title,
            doOnDate: DoOnDate(try fixtureDate(2030, 1, 2, at: hour, minute: 0, calendar: calendar))
        )
    }

}
