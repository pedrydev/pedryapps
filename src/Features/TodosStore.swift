import Foundation
import Observation

@MainActor
@Observable
final class TodosStore {
    private(set) var todos: [Todo] = []
    private(set) var errorMessage: String?
    var undoManager: UndoManager?

    private let documentStore: JSONDocumentStore<TodosDocument>?

    init(documentStore: JSONDocumentStore<TodosDocument>? = nil) {
        var setupError: String?
        if let documentStore {
            self.documentStore = documentStore
        } else {
            do {
                self.documentStore = try JSONDocumentStore(filename: "todos.json")
            } catch {
                self.documentStore = nil
                setupError = error.localizedDescription
            }
        }
        errorMessage = setupError
        load()
    }

    func load() {
        guard let documentStore else { return }
        do {
            todos = try documentStore.load()?.todos ?? []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTodo(_ title: String, doOnDate: DoOnDate = DoOnDate()) {
        guard Todo.hasText(title), doOnDate.isUpcoming else { return }
        mutate { $0.append(Todo(title: title, doOnDate: doOnDate)) }
    }

    func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        guard doOnDate.isUpcoming else { return }
        mutate { todos in
            guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
            todos[index].doOnDate = doOnDate
        }
    }

    func checkOff(_ todo: Todo) {
        checkOff(ids: [todo.id])
    }

    func checkOff(ids: Set<Todo.ID>) {
        let removed = todos.enumerated().filter { ids.contains($0.element.id) }
        guard !removed.isEmpty else { return }
        guard mutate({ $0.removeAll { ids.contains($0.id) } }) else { return }
        registerUndo { store in store.restore(removed) }
    }

    func moveTodo(from source: IndexSet, to destination: Int) {
        mutate { $0.move(fromOffsets: source, toOffset: destination) }
    }

    private func restore(_ removed: [(offset: Int, element: Todo)]) {
        let restored = mutate { current in
            for item in removed.sorted(by: { $0.offset < $1.offset }) {
                current.insert(item.element, at: min(item.offset, current.count))
            }
        }
        guard restored else { return }
        registerUndo { store in store.checkOff(ids: Set(removed.map(\.element.id))) }
    }

    private func registerUndo(_ handler: @escaping (TodosStore) -> Void) {
        undoManager?.registerUndo(withTarget: self, handler: handler)
        undoManager?.setActionName("Check Off")
    }

    @discardableResult
    private func mutate(_ change: (inout [Todo]) -> Void) -> Bool {
        let previous = todos
        change(&todos)
        guard persist() else {
            todos = previous
            return false
        }
        return true
    }

    private func persist() -> Bool {
        guard let documentStore else { return false }
        do {
            try documentStore.save(TodosDocument(todos: todos))
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
