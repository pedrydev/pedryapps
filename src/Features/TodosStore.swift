import Foundation
import SwiftUI

@MainActor
final class TodosStore: ObservableObject {
    @Published private(set) var todos: [Todo] = []
    @Published private(set) var errorMessage: String?

    private let documentStore: JSONDocumentStore<TodosDocument>

    init(documentStore: JSONDocumentStore<TodosDocument>) {
        self.documentStore = documentStore
    }

    convenience init() throws {
        let documentStore = try JSONDocumentStore<TodosDocument>(filename: "todos.json")
        self.init(documentStore: documentStore)
    }

    func load() {
        do {
            todos = try documentStore.load()?.todos ?? []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTodo(_ title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        mutate { $0.append(Todo(title: title)) }
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
