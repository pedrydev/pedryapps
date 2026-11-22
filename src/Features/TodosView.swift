import SwiftUI

struct TodosView: View {
    @ObservedObject var store: TodosStore
    @State private var newTodoTitle = ""
    @State private var newTodoDoOnDate = Calendar.current.startOfDay(for: Date())

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
            DatePicker("Do-on date", selection: $newTodoDoOnDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: 160)
                .help("Do-on date")
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
                        Spacer(minLength: 8)
                        DatePicker(
                            "Do-on date",
                            selection: Binding(
                                get: { todo.doOnDate },
                                set: { store.setDoOnDate($0, for: todo) }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: 160)
                        .help("Do-on date")
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
        store.addTodo(newTodoTitle, doOnDate: newTodoDoOnDate)
        newTodoTitle = ""
        newTodoDoOnDate = Calendar.current.startOfDay(for: Date())
    }
}
