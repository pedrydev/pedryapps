import Foundation

nonisolated struct TodosOverview {
    let items: [Todo]
    let additionalCount: Int

    static func make(
        from todos: [Todo],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> TodosOverview {
        let candidates = todos.enumerated().filter { _, todo in
            todo.doOnDate.date > now
                && calendar.isDate(todo.doOnDate.date, equalTo: now, toGranularity: .day)
        }
        let ordered = candidates.sorted { lhs, rhs in
            let left = lhs.element.doOnDate.date
            let right = rhs.element.doOnDate.date
            if left != right { return left < right }
            return lhs.offset < rhs.offset
        }
        let items = Array(ordered.prefix(5).map(\.element))
        return TodosOverview(items: items, additionalCount: max(0, ordered.count - items.count))
    }
}
