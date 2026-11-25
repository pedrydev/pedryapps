import Foundation
import Observation

@MainActor
@Observable
final class TodosStore {
    private(set) var categories: [Category] = []
    private(set) var todos: [Todo] = []
    private(set) var errorMessage: String?
    private(set) var storeErrorMessage: String?
    private(set) var isBoardLoaded = false
    private(set) var saveFailurePending = false
    var undoManager: UndoManager?

    private let documentStore: JSONDocumentStore<TodosDocument>?

    init(documentStore: JSONDocumentStore<TodosDocument>? = nil) {
        var setupError: String?
        if let documentStore {
            self.documentStore = documentStore
        } else {
            do {
                self.documentStore = try JSONDocumentStore(filename: "board.json")
            } catch {
                self.documentStore = nil
                setupError = error.localizedDescription
            }
        }
        if let setupError {
            setStoreError(setupError)
        }
        load()
    }

    func load() {
        guard let documentStore else { return }
        do {
            let document = try documentStore.load() ?? TodosDocument()
            categories = document.categories
            todos = document.todos
            isBoardLoaded = true
            if !saveFailurePending {
                clearStoreErrorState()
            }
        } catch {
            setStoreError(error.localizedDescription)
        }
    }

    func todos(in category: Category) -> [Todo] {
        todos.filter { $0.categoryID == category.id }
    }

    @discardableResult
    func addCategory() -> Category? {
        addCategory(availableCategoryName())
    }

    @discardableResult
    func addCategory(_ name: String) -> Category? {
        guard let name = Category.normalizedName(name), isCategoryNameAvailable(name) else { return nil }
        let category = Category(name: name)
        guard
            mutateWithUndo(
                actionName: "Add Category",
                { document in
                    var next = document
                    next.categories.append(category)
                    return next
                })
        else { return nil }
        return category
    }

    @discardableResult
    func renameCategory(_ category: Category, to name: String) -> Bool {
        guard let name = Category.normalizedName(name),
            isCategoryNameAvailable(name, excluding: category.id)
        else { return false }
        return mutateWithUndo(actionName: "Rename Category") { document in
            var next = document
            guard let index = next.categories.firstIndex(where: { $0.id == category.id }) else { return nil }
            next.categories[index].name = name
            return next
        }
    }

    @discardableResult
    func moveCategories(from source: IndexSet, to destination: Int) -> Bool {
        mutateWithUndo(actionName: "Reorder Category") { document in
            var next = document
            next.categories.move(fromOffsets: source, toOffset: destination)
            guard next.categories != document.categories else { return nil }
            return next
        }
    }

    @discardableResult
    func deleteCategory(_ category: Category) -> Bool {
        mutateWithUndo(actionName: "Delete Category") { document in
            var next = document
            guard next.categories.count > 1,
                let index = next.categories.firstIndex(where: { $0.id == category.id })
            else { return nil }
            next.todos.removeAll { $0.categoryID == category.id }
            next.categories.remove(at: index)
            return next
        }
    }

    @discardableResult
    func addTodo(_ title: String, in category: Category, doOnDate: DoOnDate = DoOnDate()) -> Bool {
        guard Todo.hasText(title) else {
            errorMessage = "Enter a Todo title."
            return false
        }
        guard doOnDate.isUpcoming else {
            errorMessage = "Choose a future do-on date."
            return false
        }
        guard categories.contains(where: { $0.id == category.id }) else {
            errorMessage = "Choose an existing Category."
            return false
        }
        return mutate { document in
            var next = document
            next.todos.append(Todo(categoryID: category.id, title: title, doOnDate: doOnDate))
            return next
        }
    }

    @discardableResult
    func moveTodo(_ todo: Todo, to category: Category, at insertionIndex: Int) -> Bool {
        mutateWithUndo(actionName: "Move Todo") { document in
            var next = document
            guard let sourceIndex = next.todos.firstIndex(where: { $0.id == todo.id }),
                next.categories.contains(where: { $0.id == category.id })
            else { return nil }

            let stored = next.todos[sourceIndex]
            let sourcePosition = next.todos[..<sourceIndex].count(where: { $0.categoryID == category.id })
            next.todos.remove(at: sourceIndex)
            let destinationTodos = next.todos.filter { $0.categoryID == category.id }
            let adjustedIndex =
                stored.categoryID == category.id && insertionIndex > sourcePosition
                ? insertionIndex - 1
                : insertionIndex
            let target = min(max(0, adjustedIndex), destinationTodos.count)
            let globalIndex: Int
            if target < destinationTodos.count {
                let followingID = destinationTodos[target].id
                guard let index = next.todos.firstIndex(where: { $0.id == followingID }) else { return nil }
                globalIndex = index
            } else if let lastID = destinationTodos.last?.id {
                guard let index = next.todos.firstIndex(where: { $0.id == lastID }) else { return nil }
                globalIndex = index + 1
            } else {
                globalIndex = next.todos.count
            }
            let moved = Todo(
                id: stored.id,
                categoryID: category.id,
                title: stored.title,
                doOnDate: stored.doOnDate
            )
            next.todos.insert(moved, at: globalIndex)
            guard next.todos != document.todos else { return nil }
            return next
        }
    }

    @discardableResult
    func moveTodo(_ todo: Todo, to category: Category) -> Bool {
        let count = todos.count(where: { $0.categoryID == category.id && $0.id != todo.id })
        return moveTodo(todo, to: category, at: count)
    }

    func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        guard doOnDate.isUpcoming else {
            errorMessage = "Choose a future do-on date."
            return
        }
        mutate { document in
            var next = document
            guard let index = next.todos.firstIndex(where: { $0.id == todo.id }) else { return nil }
            next.todos[index].doOnDate = doOnDate
            return next
        }
    }

    func checkOff(_ todo: Todo) {
        checkOff(ids: [todo.id])
    }

    func checkOff(ids: Set<Todo.ID>) {
        mutateWithUndo(actionName: "Check Off") { document in
            var next = document
            next.todos.removeAll { ids.contains($0.id) }
            guard next.todos != document.todos else { return nil }
            return next
        }
    }

    private var document: TodosDocument {
        TodosDocument(categories: categories, todos: todos)
    }

    private func isCategoryNameAvailable(_ name: String, excluding id: Category.ID? = nil) -> Bool {
        !categories.contains { category in
            category.id != id && category.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func availableCategoryName() -> String {
        var name = "New Category"
        var suffix = 2
        while !isCategoryNameAvailable(name) {
            name = "New Category \(suffix)"
            suffix += 1
        }
        return name
    }

    @discardableResult
    private func mutate(_ change: (TodosDocument) -> TodosDocument?) -> Bool {
        guard let next = change(document) else { return false }
        return apply(next)
    }

    @discardableResult
    private func mutateWithUndo(actionName: String, _ change: (TodosDocument) -> TodosDocument?) -> Bool {
        let previous = document
        guard mutate(change) else { return false }
        registerUndo(actionName: actionName) { store in store.applyUndoSnapshot(previous, actionName: actionName) }
        return true
    }

    private func applyUndoSnapshot(_ snapshot: TodosDocument, actionName: String) {
        let previous = document
        guard apply(snapshot) else { return }
        registerUndo(actionName: actionName) { store in store.applyUndoSnapshot(previous, actionName: actionName) }
    }

    @discardableResult
    private func apply(_ next: TodosDocument) -> Bool {
        guard persist(next) else { return false }
        categories = next.categories
        todos = next.todos
        return true
    }

    private func persist(_ document: TodosDocument) -> Bool {
        guard let documentStore else { return false }
        do {
            try documentStore.save(document)
            clearStoreErrorState()
            return true
        } catch {
            setStoreError(error.localizedDescription)
            saveFailurePending = true
            return false
        }
    }

    private func setStoreError(_ message: String) {
        errorMessage = message
        storeErrorMessage = message
    }

    private func clearStoreErrorState() {
        errorMessage = nil
        storeErrorMessage = nil
        saveFailurePending = false
    }

    private func registerUndo(actionName: String, _ handler: @escaping (TodosStore) -> Void) {
        undoManager?.registerUndo(withTarget: self, handler: handler)
        undoManager?.setActionName(actionName)
    }
}
