import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosStoreTests {
    @Test func loadingRestoresPersistedCategoriesAndTodos() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "board.json")
        let work = PedryApps.Category(name: "Work")
        let todo = Todo(categoryID: work.id, title: "Buy milk")
        try documentStore.save(TodosDocument(categories: [work], todos: [todo]))
        let store = makeStore(in: directory.url)

        store.load()

        #expect(store.categories == [work])
        #expect(store.todos == [todo])
        #expect(store.todos(in: work) == [todo])
    }

    @Test func loadingFlatListDocumentStartsWithAnEmptyBoard() throws {
        let directory = try TemporaryDirectory()
        try Data(#"{"todos":[{"title":"Buy milk"}]}"#.utf8)
            .write(to: directory.url.appendingPathComponent("todos.json"))
        let store = makeStore(in: directory.url)

        #expect(store.categories.isEmpty)
        #expect(store.todos.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func addingCategoryAppendsItWithItsName() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        let work = try addCategory(to: store, named: "Work")
        let home = try addCategory(to: store, named: "Home")

        #expect(store.categories == [work, home])
        #expect(store.categories.map(\.name) == ["Work", "Home"])
    }

    @Test func addCategoryUsesAUniqueDefaultName() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        let first = try #require(store.addCategory())
        let second = try #require(store.addCategory())

        #expect(first.name == "New Category")
        #expect(second.name == "New Category 2")
    }

    @Test func categoryNamesAreTrimmed() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        let work = try addCategory(to: store, named: "  Work  ")
        try #require(store.renameCategory(work, to: "\nHome\t"))

        #expect(store.categories.map(\.name) == ["Home"])
    }

    @Test func blankAndDuplicateCategoryNamesAreRejectedWithoutMutation() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        let home = try addCategory(to: store, named: "Home")

        #expect(store.addCategory("   ") == nil)
        #expect(store.addCategory("home") == nil)
        #expect(store.renameCategory(work, to: "") == false)
        #expect(store.renameCategory(work, to: " HOME ") == false)
        #expect(store.categories == [work, home])
    }

    @Test func renamingCategoryKeepsItsIdentityAndPosition() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        try addCategory(to: store, named: "Home")

        #expect(store.renameCategory(work, to: "Office"))

        #expect(store.categories[0].id == work.id)
        #expect(store.categories.map(\.name) == ["Office", "Home"])
    }

    @Test func renamingCategoryToItsOwnNameIsAllowed() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        #expect(store.renameCategory(work, to: "work"))

        #expect(store.categories.map(\.name) == ["work"])
    }

    @Test func categoriesReorderAndSurviveReload() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        try addCategory(to: store, named: "Work")
        try addCategory(to: store, named: "Home")
        try addCategory(to: store, named: "Errands")

        #expect(store.moveCategories(from: IndexSet(integer: 2), to: 0))
        let reloaded = makeStore(in: directory.url)
        reloaded.load()

        #expect(reloaded.categories.map(\.name) == ["Errands", "Work", "Home"])
    }

    @Test func deletingAnEmptyCategorySurvivesReload() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        try addCategory(to: store, named: "Home")

        #expect(store.deleteCategory(work))
        let reloaded = makeStore(in: directory.url)
        reloaded.load()

        #expect(reloaded.categories.map(\.name) == ["Home"])
    }

    @Test func deletingTheLastCategoryIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        #expect(store.deleteCategory(work) == false)

        #expect(store.categories == [work])
    }

    @Test func deletingACategoryWithTodosIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        try addCategory(to: store, named: "Home")
        store.addTodo("Buy milk", in: work)

        #expect(store.deleteCategory(work) == false)

        #expect(store.categories.map(\.name) == ["Work", "Home"])
        #expect(store.todos(in: work).map(\.title) == ["Buy milk"])
    }

    @Test func categoryCreationCanBeUndoneAndRedone() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let undoManager = UndoManager()
        store.undoManager = undoManager
        let work = try #require(store.addCategory())

        undoManager.undo()
        #expect(store.categories.isEmpty)
        let afterUndo = makeStore(in: directory.url)
        afterUndo.load()
        #expect(afterUndo.categories.isEmpty)

        undoManager.redo()
        #expect(store.categories == [work])
        let afterRedo = makeStore(in: directory.url)
        afterRedo.load()
        #expect(afterRedo.categories == [work])
    }

    @Test func categoryRenameCanBeUndoneAndRedone() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        let undoManager = UndoManager()
        store.undoManager = undoManager

        try #require(store.renameCategory(work, to: "Office"))
        undoManager.undo()
        #expect(store.categories.map(\.name) == ["Work"])
        let afterUndo = makeStore(in: directory.url)
        afterUndo.load()
        #expect(afterUndo.categories.map(\.name) == ["Work"])
        undoManager.redo()
        #expect(store.categories.map(\.name) == ["Office"])

        let reloaded = makeStore(in: directory.url)
        reloaded.load()
        #expect(reloaded.categories.map(\.name) == ["Office"])
    }

    @Test func categoryReorderCanBeUndoneAndRedone() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        try addCategory(to: store, named: "Work")
        try addCategory(to: store, named: "Home")
        let undoManager = UndoManager()
        store.undoManager = undoManager

        try #require(store.moveCategories(from: IndexSet(integer: 1), to: 0))
        undoManager.undo()
        #expect(store.categories.map(\.name) == ["Work", "Home"])
        let afterUndo = makeStore(in: directory.url)
        afterUndo.load()
        #expect(afterUndo.categories.map(\.name) == ["Work", "Home"])
        undoManager.redo()
        #expect(store.categories.map(\.name) == ["Home", "Work"])

        let reloaded = makeStore(in: directory.url)
        reloaded.load()
        #expect(reloaded.categories.map(\.name) == ["Home", "Work"])
    }

    @Test func categoryDeletionCanBeUndoneAndRedone() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        let home = try addCategory(to: store, named: "Home")
        let undoManager = UndoManager()
        store.undoManager = undoManager

        try #require(store.deleteCategory(work))
        undoManager.undo()
        #expect(store.categories == [work, home])
        let afterUndo = makeStore(in: directory.url)
        afterUndo.load()
        #expect(afterUndo.categories == [work, home])
        undoManager.redo()
        #expect(store.categories == [home])

        let reloaded = makeStore(in: directory.url)
        reloaded.load()
        #expect(reloaded.categories == [home])
    }

    @Test func addingTodoAppendsItWithEnteredText() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        store.addTodo("Buy milk", in: work)
        store.addTodo("  Call Sam  ", in: work)

        #expect(store.todos(in: work).map(\.title) == ["Buy milk", "  Call Sam  "])
    }

    @Test func addedTodoDefaultsToAnUpcomingWholeHour() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        store.addTodo("Buy milk", in: work)

        let actual = try #require(store.todos.first?.doOnDate.date)
        let components = Calendar.current.dateComponents([.minute, .second], from: actual)
        #expect(actual > Date())
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func addingTodoWithPastStartIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        store.addTodo("Buy milk", in: work, doOnDate: DoOnDate(Date().addingTimeInterval(-3600)))

        #expect(store.todos.isEmpty)
    }

    @Test func addingTodoToAMissingCategoryIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.addTodo("Buy milk", in: PedryApps.Category(name: "Ghost"))

        #expect(store.todos.isEmpty)
    }

    @Test func changingToPastStartIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        store.addTodo("Buy milk", in: work, doOnDate: DoOnDate(Date().addingTimeInterval(3600)))
        let original = try #require(store.todos.first?.doOnDate)

        store.setDoOnDate(DoOnDate(Date().addingTimeInterval(-3600)), for: store.todos[0])

        #expect(store.todos.first?.doOnDate == original)
    }

    @Test func addingWhitespaceOnlyTodoIsRejected() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")

        store.addTodo("", in: work)
        store.addTodo("   \n\t ", in: work)

        #expect(store.todos.isEmpty)
    }

    @Test func changingDoOnDatePersistsWithoutChangingTitleOrOrder() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)
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
        let work = try addCategory(to: first, named: "Work")

        first.addTodo("Buy milk", in: work)
        let second = makeStore(in: directory.url)
        second.load()

        #expect(second.todos.map(\.title) == ["Buy milk"])
        #expect(second.todos.first?.categoryID == work.id)
    }

    @Test func loadingMissingDocumentStartsEmpty() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.load()

        #expect(store.categories.isEmpty)
        #expect(store.todos.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func loadingMalformedDocumentSurfacesErrorAndKeepsLastKnownState() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        try addCategory(to: store, named: "Work")
        try Data("not json".utf8).write(to: directory.url.appendingPathComponent("board.json"))

        store.load()

        #expect(store.errorMessage != nil)
        #expect(store.categories.map(\.name) == ["Work"])
    }

    @Test func failedSaveSurfacesErrorAndRollsBackMutation() {
        let missingDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: missingDirectory, filename: "board.json")
        )

        #expect(store.addCategory("Work") == nil)
        #expect(store.categories.isEmpty)
        #expect(store.errorMessage != nil)
    }

    @Test func checkingOffRemovesOnlyTheCheckedOffTodo() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)
        let original = store.todos

        store.checkOff(original[0])

        #expect(store.todos.map(\.title) == ["Call Sam"])
        #expect(store.todos.first?.id == original[1].id)
    }

    @Test func checkingOffSelectedTodosRemovesOnlyThose() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)
        store.addTodo("Pay bills", in: work)
        let ids = [store.todos[0].id, store.todos[2].id]

        store.checkOff(ids: Set(ids))

        #expect(store.todos.map(\.title) == ["Call Sam"])
    }

    @Test func checkingOffCanBeUndoneAndRedone() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        let undoManager = UndoManager()
        store.undoManager = undoManager
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)
        store.addTodo("Pay bills", in: work)

        store.checkOff(ids: [store.todos[1].id])

        #expect(store.todos.map(\.title) == ["Buy milk", "Pay bills"])

        undoManager.undo()
        #expect(store.todos.map(\.title) == ["Buy milk", "Call Sam", "Pay bills"])

        undoManager.redo()
        #expect(store.todos.map(\.title) == ["Buy milk", "Pay bills"])
    }

    @Test func undoingCheckOffPersistsTheRestoredTodo() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        let undoManager = UndoManager()
        store.undoManager = undoManager
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)

        store.checkOff(store.todos[0])
        undoManager.undo()

        let reloaded = makeStore(in: directory.url)
        reloaded.load()
        #expect(reloaded.todos.map(\.title) == ["Buy milk", "Call Sam"])
    }

    @Test func checkedOffTodoStaysRemovedAfterReload() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let work = try addCategory(to: store, named: "Work")
        store.addTodo("Buy milk", in: work)
        store.addTodo("Call Sam", in: work)

        store.checkOff(store.todos[0])
        let reloaded = makeStore(in: directory.url)
        reloaded.load()

        #expect(reloaded.todos.map(\.title) == ["Call Sam"])
    }

    private func makeStore(in directory: URL) -> TodosStore {
        TodosStore(documentStore: JSONDocumentStore(directory: directory, filename: "board.json"))
    }

    @discardableResult
    private func addCategory(to store: TodosStore, named name: String) throws -> PedryApps.Category {
        try #require(store.addCategory(name))
    }
}
