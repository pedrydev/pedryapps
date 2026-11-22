import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosStoreTests {
    @Test func loadingRestoresPersistedTodos() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory, filename: "todos.json")
        try documentStore.save(TodosDocument(todos: [Todo(title: "Buy milk")]))
        let store = makeStore(in: directory)

        store.load()

        #expect(store.todos.map(\.title) == ["Buy milk"])
    }

    @Test func addingTodoAppendsItWithEnteredText() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)

        store.addTodo("Buy milk")
        store.addTodo("  Call Sam  ")

        #expect(store.todos.map(\.title) == ["Buy milk", "  Call Sam  "])
    }

    @Test func addedTodoDefaultsToStartOfToday() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        let calendar = Calendar.current
        let before = calendar.startOfDay(for: Date())

        store.addTodo("Buy milk")

        let after = calendar.startOfDay(for: Date())
        let actual = store.todos.first?.doOnDate
        #expect(actual == before || actual == after)
    }

    @Test func addingWhitespaceOnlyTodoIsRejected() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)

        store.addTodo("")
        store.addTodo("   \n\t ")

        #expect(store.todos.isEmpty)
    }

    @Test func changingDoOnDatePersistsWithoutChangingTitleOrOrder() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        let target = store.todos[0]
        let otherDate = store.todos[1].doOnDate
        let calendar = Calendar.current
        let afternoon = calendar.date(from: DateComponents(year: 2030, month: 1, day: 2))!
            .addingTimeInterval(12 * 60 * 60)
        let expected = calendar.startOfDay(for: afternoon)

        store.setDoOnDate(afternoon, for: target)

        #expect(store.todos.map(\.title) == ["Buy milk", "Call Sam"])
        #expect(store.todos[0].doOnDate == expected)
        #expect(store.todos[1].doOnDate == otherDate)
        let reloaded = makeStore(in: directory)
        reloaded.load()
        #expect(reloaded.todos[0].doOnDate == expected)
        #expect(reloaded.todos[1].doOnDate == otherDate)
    }

    @Test func addedTodoIsAvailableToANewStoreInstance() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = makeStore(in: directory)

        first.addTodo("Buy milk")
        let second = makeStore(in: directory)
        second.load()

        #expect(second.todos.map(\.title) == ["Buy milk"])
    }

    @Test func loadingMissingDocumentStartsEmpty() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)

        store.load()

        #expect(store.todos.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func loadingMalformedDocumentSurfacesErrorAndKeepsLastKnownTodos() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        try Data("not json".utf8).write(to: directory.appendingPathComponent("todos.json"))

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
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        let original = store.todos

        store.checkOff(original[0])

        #expect(store.todos.map(\.title) == ["Call Sam"])
        #expect(store.todos.first?.id == original[1].id)
    }

    @Test func checkedOffTodoStaysRemovedAfterReload() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")

        store.checkOff(store.todos[0])
        let reloaded = makeStore(in: directory)
        reloaded.load()

        #expect(reloaded.todos.map(\.title) == ["Call Sam"])
    }

    @Test func movingTodoPreservesIdentityAndText() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        store.addTodo("Pay bills")
        let original = store.todos

        store.moveTodo(from: IndexSet(integer: 2), to: 0)

        #expect(store.todos.map(\.title) == ["Pay bills", "Buy milk", "Call Sam"])
        #expect(Set(store.todos.map(\.id)) == Set(original.map(\.id)))
    }

    @Test func reorderedListSurvivesReload() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(in: directory)
        store.addTodo("Buy milk")
        store.addTodo("Call Sam")
        store.addTodo("Pay bills")

        store.moveTodo(from: IndexSet(integer: 2), to: 0)
        let reloaded = makeStore(in: directory)
        reloaded.load()

        #expect(reloaded.todos.map(\.title) == ["Pay bills", "Buy milk", "Call Sam"])
    }

    private func makeStore(in directory: URL) -> TodosStore {
        TodosStore(documentStore: JSONDocumentStore(directory: directory, filename: "todos.json"))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
