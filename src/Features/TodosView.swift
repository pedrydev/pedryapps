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
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 24) {
                        ForEach(store.categories) { category in
                            BoardCategoryView(
                                category: category,
                                todos: visibleTodos(in: category),
                                errorMessage: store.errorMessage,
                                selectedTodoIDs: $selectedTodoIDs,
                                checkOff: checkOff,
                                addTodo: { title, doOnDate in
                                    store.addTodo(title, in: category, doOnDate: doOnDate)
                                }
                            )
                            .frame(width: columnWidth(in: geometry.size.width))
                        }
                    }
                    .padding(16)
                }
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

    private func columnWidth(in containerWidth: CGFloat) -> CGFloat {
        let visibleCount = min(5, max(1, store.categories.count))
        let spacing: CGFloat = 24
        let padding: CGFloat = 32
        let available = containerWidth - padding - spacing * CGFloat(visibleCount - 1)
        return min(520, max(240, available / CGFloat(visibleCount)))
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

}
