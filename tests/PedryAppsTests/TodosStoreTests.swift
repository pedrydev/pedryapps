import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosStoreTests {
    @Test func loadingRestoresPersistedTodos() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "todos.json")
        try documentStore.save(TodosDocument(todos: [Todo(title: "Buy milk")]))
        let store = makeStore(in: directory.url)

        store.load()

        #expect(store.todos.map(\.title) == ["Buy milk"])
    }

    @Test func addingTodoAppendsItWithEnteredText() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.addTodo("Buy milk")
        store.addTodo("  Call Sam  ")

        #expect(store.todos.map(\.title) == ["Buy milk", "  Call Sam  "])
    }

    @Test func addedTodoDefaultsToAnUpcomingWholeHour() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.addTodo("Buy milk")

        let actual = try #require(store.todos.first?.doOnDate.date)
        let components = Calendar.current.dateComponents([.minute, .second], from: actual)
        #expect(actual > Date())
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func addingTodoWithPastStartIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.addTodo("Buy milk", doOnDate: DoOnDate(Date().addingTimeInterval(-3600)))

        #expect(store.todos.isEmpty)
    }

    @Test func changingToPastStartIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk", doOnDate: DoOnDate(Date().addingTimeInterval(3600)))
        let original = try #require(store.todos.first?.doOnDate)

        store.setDoOnDate(DoOnDate(Date().addingTimeInterval(-3600)), for: store.todos[0])

        #expect(store.todos.first?.doOnDate == original)
    }

    @Test func addingWhitespaceOnlyTodoIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.addTodo("")
        store.addTodo("   \n\t ")

        #expect(store.todos.isEmpty)
    }

    @Test func changingDoOnDatePersistsWithoutChangingTitleOrOrder() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        let target = store.todos[0]
        let otherDate = store.todos[1].doOnDate
        let calendar = Calendar.current
        let day = try #require(calendar.date(from: DateComponents(year: 2030, month: 1, day: 2)))
        let expected = DoOnDate(day.addingTimeInterval(12 * 60 * 60))

        store.setDoOnDate(expected, for: target)

        #expect(store.todos.map(\.title) == ["Buy milk", "Call Sam"])
        #expect(store.todos[0].doOnDate == expected)
        #expect(store.todos[1].doOnDate == otherDate)
        let reloaded = makeStore(in: directory.url)
        reloaded.load()
        #expect(reloaded.todos[0].doOnDate == expected)
        #expect(reloaded.todos[1].doOnDate == otherDate)
    }

    @Test func addedTodoIsAvailableToANewStoreInstance() throws {
        let directory = try TemporaryDirectory()
        let first = makeStore(in: directory.url)

        first.addTodo("Buy milk")
        let second = makeStore(in: directory.url)
        second.load()

        #expect(second.todos.map(\.title) == ["Buy milk"])
    }

    @Test func loadingMissingDocumentStartsEmpty() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.load()

        #expect(store.todos.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func loadingMalformedDocumentSurfacesErrorAndKeepsLastKnownTodos() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        try Data("not json".utf8).write(to: directory.url.appendingPathComponent("todos.json"))

        store.load()

        #expect(store.errorMessage != nil)
        #expect(store.todos.map(\.title) == ["Buy milk"])
    }

    @Test func failedSaveSurfacesErrorAndRollsBackMutation() {
        let missingDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: missingDirectory, filename: "todos.json")
        )

        store.addTodo("Buy milk")

        #expect(store.todos.isEmpty)
        #expect(store.errorMessage != nil)
    }

    @Test func checkingOffRemovesOnlyTheCheckedOffTodo() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        let original = store.todos

        store.checkOff(original[0])

        #expect(store.todos.map(\.title) == ["Call Sam"])
        #expect(store.todos.first?.id == original[1].id)
    }

    @Test func checkedOffTodoStaysRemovedAfterReload() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")

        store.checkOff(store.todos[0])
        let reloaded = makeStore(in: directory.url)
        reloaded.load()

        #expect(reloaded.todos.map(\.title) == ["Call Sam"])
    }

    @Test func movingTodoPreservesIdentityAndText() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        store.addTodo("Pay bills")
        let original = store.todos

        store.moveTodo(from: IndexSet(integer: 2), to: 0)

        #expect(store.todos.map(\.title) == ["Pay bills", "Buy milk", "Call Sam"])
        #expect(Set(store.todos.map(\.id)) == Set(original.map(\.id)))
    }

    @Test func reorderedListSurvivesReload() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        store.addTodo("Pay bills")

        store.moveTodo(from: IndexSet(integer: 2), to: 0)
        let reloaded = makeStore(in: directory.url)
        reloaded.load()

        #expect(reloaded.todos.map(\.title) == ["Pay bills", "Buy milk", "Call Sam"])
    }

    private func makeStore(in directory: URL) -> TodosStore {
        TodosStore(documentStore: JSONDocumentStore(directory: directory, filename: "todos.json"))
    }
}
