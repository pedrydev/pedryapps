import Foundation
import Observation

@MainActor
@Observable
final class TodosStore {
    private(set) var todos: [Todo] = []
    private(set) var errorMessage: String?

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
        guard Todo.hasText(title) else { return }
        mutate { $0.append(Todo(title: title, doOnDate: doOnDate)) }
    }

    func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        mutate { todos in
            guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
            todos[index].doOnDate = doOnDate
        }
    }

    func checkOff(_ todo: Todo) {
        mutate { $0.removeAll { $0.id == todo.id } }
    }

    func moveTodo(from source: IndexSet, to destination: Int) {
        mutate { $0.move(fromOffsets: source, toOffset: destination) }
    }

    private func mutate(_ change: (inout [Todo]) -> Void) {
        let previous = todos
        change(&todos)
        if !persist() { todos = previous }
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
