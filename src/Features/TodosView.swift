import SwiftUI

struct TodosView: View {
    let store: TodosStore

    @State private var newTodoTitle = ""
    @State private var newTodoDoOnDate = DoOnDate()
    @State private var selectedTodoIDs: Set<Todo.ID> = []
    @State private var searchText = ""
    @FocusState private var isNewTodoFocused: Bool
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.undoManager) private var undoManager: UndoManager?

    private var visibleTodos: [Todo] {
        guard !searchText.isEmpty else { return store.todos }
        return store.todos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            AddTodoRow(
                title: $newTodoTitle,
                doOnDate: $newTodoDoOnDate,
                isFocused: $isNewTodoFocused,
                add: add
            )
            todosContent
            errorMessageView
        }
        .frame(minWidth: 340, minHeight: 260)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Todos")
        .toolbar(id: "Todos") {
            ToolbarItem(id: "add", placement: .primaryAction) {
                Button("Add Todo", systemImage: "plus", action: add)
                    .help("Add Todo (Command-T)")
                    .disabled(Todo.hasText(newTodoTitle) == false)
            }
            ToolbarItem(id: "checkOff", placement: .secondaryAction) {
                Button("Check Off Selected", systemImage: "checkmark.circle", action: checkOffSelection)
                    .disabled(selectedTodoIDs.isEmpty)
            }
        }
        .onAppear { store.undoManager = undoManager }
        .onReceive(NotificationCenter.default.publisher(for: .focusNewTodo)) { _ in
            isNewTodoFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .checkOffSelectedTodos)) { _ in
            checkOffSelection()
        }
    }

    @ViewBuilder
    private var todosContent: some View {
        if store.todos.isEmpty {
            emptyView
        } else {
            todoListView
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Todos", systemImage: "checkmark.circle")
        } description: {
            Text("Add a Todo above to get started.")
        }
    }

    private var todoListView: some View {
        List(selection: $selectedTodoIDs) {
            ForEach(visibleTodos) { todo in
                TodoRow(todo: todo, checkOff: checkOff, setDoOnDate: setDoOnDate)
                    .contextMenu {
                        Button("Check Off", systemImage: "checkmark.circle") {
                            checkOffFromContextMenu(todo)
                        }
                    }
            }
            .onMove { source, destination in
                if searchText.isEmpty { moveTodo(from: source, to: destination) }
            }
            .onDelete(perform: checkOff(at:))
        }
        .listStyle(.inset)
    }

    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = store.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(colorSchemeContrast == .increased ? Color.primary : Color.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private func add() {
        guard Todo.hasText(newTodoTitle) else { return }
        let doOnDate = newTodoDoOnDate.isUpcoming ? newTodoDoOnDate : DoOnDate()
        store.addTodo(newTodoTitle, doOnDate: doOnDate)
        newTodoTitle = ""
        newTodoDoOnDate = DoOnDate()
    }

    private func checkOff(_ todo: Todo) {
        store.checkOff(todo)
        selectedTodoIDs.remove(todo.id)
    }

    private func checkOffSelection() {
        store.checkOff(ids: selectedTodoIDs)
        selectedTodoIDs.removeAll()
    }

    private func checkOffFromContextMenu(_ todo: Todo) {
        if selectedTodoIDs.contains(todo.id) {
            checkOffSelection()
        } else {
            checkOff(todo)
        }
    }

    private func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        store.setDoOnDate(doOnDate, for: todo)
    }

    private func moveTodo(from source: IndexSet, to destination: Int) {
        store.moveTodo(from: source, to: destination)
    }

    private func checkOff(at offsets: IndexSet) {
        let ids = offsets.filter { visibleTodos.indices.contains($0) }.map { visibleTodos[$0].id }
        store.checkOff(ids: Set(ids))
        selectedTodoIDs.subtract(ids)
    }
}
