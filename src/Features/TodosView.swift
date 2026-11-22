import SwiftUI

struct TodosView: View {
    let store: TodosStore

    @State private var newTodoTitle = ""
    @State private var newTodoDoOnDate = DoOnDate()

    var body: some View {
        VStack(spacing: 0) {
            AddTodoRow(
                title: $newTodoTitle,
                doOnDate: $newTodoDoOnDate,
                add: add
            )

            if store.todos.isEmpty {
                ContentUnavailableView {
                    Label("No Todos", systemImage: "checkmark.circle")
                } description: {
                    Text("Add a Todo above to get started.")
                }
            } else {
                List {
                    ForEach(store.todos) { todo in
                        TodoRow(
                            todo: todo,
                            checkOff: checkOff,
                            setDoOnDate: setDoOnDate
                        )
                    }
                    .onMove(perform: moveTodo)
                }
                .listStyle(.inset)
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 340, minHeight: 260)
    }

    private func add() {
        guard Todo.hasText(newTodoTitle) else { return }
        store.addTodo(newTodoTitle, doOnDate: newTodoDoOnDate)
        newTodoTitle = ""
        newTodoDoOnDate = DoOnDate()
    }

    private func checkOff(_ todo: Todo) {
        store.checkOff(todo)
    }

    private func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        store.setDoOnDate(doOnDate, for: todo)
    }

    private func moveTodo(from source: IndexSet, to destination: Int) {
        store.moveTodo(from: source, to: destination)
    }
}
