import Foundation

nonisolated struct TodosOverview {
    let items: [Todo]
    let additionalCount: Int

    static func make(
        from todos: [Todo],
        categories: [Category] = [],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> TodosOverview {
        let categoryOrder = Dictionary(uniqueKeysWithValues: categories.enumerated().map { ($1.id, $0) })
        let categoryTodos = Dictionary(grouping: todos, by: \.categoryID)
        let position = Dictionary(
            uniqueKeysWithValues: categoryTodos.flatMap { _, values in
                values.enumerated().map { ($1.id, $0) }
            }
        )
        let candidates = todos.filter { todo in
            todo.doOnDate.date > now
                && calendar.isDate(todo.doOnDate.date, equalTo: now, toGranularity: .day)
        }
        let ordered = candidates.sorted { lhs, rhs in
            let leftDate = lhs.doOnDate.date
            let rightDate = rhs.doOnDate.date
            if leftDate != rightDate { return leftDate < rightDate }

            let leftCategory = categoryOrder[lhs.categoryID] ?? .max
            let rightCategory = categoryOrder[rhs.categoryID] ?? .max
            if leftCategory != rightCategory { return leftCategory < rightCategory }

            let leftPosition = position[lhs.id] ?? .max
            let rightPosition = position[rhs.id] ?? .max
            return leftPosition < rightPosition
        }
        let items = Array(ordered.prefix(5))
        return TodosOverview(items: items, additionalCount: max(0, ordered.count - items.count))
    }
}
