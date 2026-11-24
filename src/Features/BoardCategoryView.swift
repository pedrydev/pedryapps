import SwiftUI

struct BoardCategoryView: View {
    let category: Category
    let todos: [Todo]
    let errorMessage: String?
    @Binding var selectedTodoIDs: Set<Todo.ID>
    let checkOff: (Todo) -> Void
    let setDoOnDate: (DoOnDate, Todo) -> Void
    let addTodo: (String, DoOnDate) -> Bool

    @State private var isAddingTodo = false
    @State private var title = ""
    @State private var doOnDate = DoOnDate()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.headline)
                .lineLimit(1)
            Button("Add Todo", systemImage: "plus", action: reveal)
                .buttonStyle(.borderless)
            List(selection: $selectedTodoIDs) {
                ForEach(todos) { todo in
                    TodoRow(todo: todo, checkOff: checkOff, setDoOnDate: setDoOnDate)
                }
            }
            .listStyle(.inset)
            .frame(height: 360)
        }
        .frame(width: 280)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $isAddingTodo) {
            AddTodoDialog(
                category: category,
                title: $title,
                doOnDate: $doOnDate,
                errorMessage: errorMessage,
                add: submitNewTodo,
                cancel: cancel
            )
        }
    }

    private func reveal() {
        resetDraft()
        isAddingTodo = true
    }

    private func submitNewTodo() -> Bool {
        guard addTodo(title, doOnDate) else { return false }
        resetDraft()
        return true
    }

    private func cancel() {
        resetDraft()
    }

    private func resetDraft() {
        title = ""
        doOnDate = DoOnDate()
    }
}
