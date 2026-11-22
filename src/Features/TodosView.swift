import SwiftUI

struct TodosView: View {
    @ObservedObject var store: TodosStore
    @State private var newTodoTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            addRow
            content
            errorRow
        }
        .frame(minWidth: 340, minHeight: 260)
        .onAppear { store.load() }
    }

    private var addRow: some View {
        HStack {
            TextField("Add a Todo", text: $newTodoTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)
            Button("Add", action: add)
                .keyboardShortcut(.defaultAction)
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if store.todos.isEmpty {
            ContentUnavailableView {
                Label("No Todos", systemImage: "checkmark.circle")
            } description: {
                Text("Add a Todo above to get started.")
            }
        } else {
            List {
                ForEach(store.todos) { todo in
                    HStack {
                        Button {
                            store.checkOff(todo)
                        } label: {
                            Image(systemName: "circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Check off")

                        Text(todo.title)
                    }
                }
                .onMove { source, destination in
                    store.moveTodo(from: source, to: destination)
                }
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private var errorRow: some View {
        if let errorMessage = store.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private func add() {
        guard !newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.addTodo(newTodoTitle)
        newTodoTitle = ""
    }
}
