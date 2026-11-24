import SwiftUI

struct TodosView: View {
    let store: TodosStore

    @State private var selectedTodoIDs: Set<Todo.ID> = []
    @State private var searchText = ""
    @State private var isManagingCategories = false
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.undoManager) private var undoManager: UndoManager?

    var body: some View {
        VStack(spacing: 0) {
            boardContent
            errorMessageView
        }
        .frame(minWidth: 520, minHeight: 460)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Todos")
        .sheet(isPresented: $isManagingCategories) {
            ManageCategoriesView(store: store)
        }
        .toolbar(id: "Todos") {
            ToolbarItem(id: "manageCategories", placement: .primaryAction) {
                Button("Manage Categories", systemImage: "square.grid.2x2", action: openCategories)
            }
            ToolbarItem(id: "checkOff", placement: .secondaryAction) {
                Button("Check Off Selected", systemImage: "checkmark.circle", action: checkOffSelection)
                    .disabled(selectedTodoIDs.isEmpty)
            }
        }
        .onAppear { store.undoManager = undoManager }
        .onReceive(NotificationCenter.default.publisher(for: .checkOffSelectedTodos)) { _ in
            checkOffSelection()
        }
    }

    @ViewBuilder
    private var boardContent: some View {
        if store.categories.isEmpty {
            ContentUnavailableView {
                Label("No Categories", systemImage: "square.grid.2x2")
            } description: {
                Text("Create a Category to start your Board.")
            } actions: {
                Button("Manage Categories", action: openCategories)
            }
        } else {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(store.categories) { category in
                        BoardCategoryView(
                            category: category,
                            todos: visibleTodos(in: category),
                            selectedTodoIDs: $selectedTodoIDs,
                            checkOff: checkOff,
                            setDoOnDate: setDoOnDate
                        )
                    }
                }
                .padding(16)
            }
        }
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

    private func visibleTodos(in category: Category) -> [Todo] {
        let categoryTodos = store.todos(in: category)
        guard !searchText.isEmpty else { return categoryTodos }
        return categoryTodos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func openCategories() {
        isManagingCategories = true
    }

    private func checkOff(_ todo: Todo) {
        store.checkOff(todo)
        selectedTodoIDs.remove(todo.id)
    }

    private func checkOffSelection() {
        store.checkOff(ids: selectedTodoIDs)
        selectedTodoIDs.removeAll()
    }

    private func setDoOnDate(_ doOnDate: DoOnDate, for todo: Todo) {
        store.setDoOnDate(doOnDate, for: todo)
    }
}
