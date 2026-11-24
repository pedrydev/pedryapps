import SwiftUI

struct BoardCategoryView: View {
    let category: Category
    let todos: [Todo]
    let categories: [Category]
    let errorMessage: String?
    let allowsReordering: Bool
    let allowsAdding: Bool
    @Binding var selectedTodoIDs: Set<Todo.ID>
    let checkOff: (Todo) -> Void
    let addTodo: (String, DoOnDate) -> Bool
    let moveTodo: (Todo, Category) -> Void
    let dropTodo: (Todo.ID, Category, Int) -> Void

    @State private var isAddingTodo = false
    @State private var title = ""
    @State private var doOnDate = DoOnDate()
    @State private var isEndDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if allowsAdding {
                    Button("Todo", systemImage: "plus", action: reveal)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Add Todo")
                }
            }
            List(selection: $selectedTodoIDs) {
                ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                    TodoRow(
                        todo: todo,
                        categories: categories,
                        index: index,
                        allowsDrop: allowsReordering,
                        checkOff: checkOff,
                        moveToCategory: moveTodo,
                        dropTodo: { id, insertionIndex in
                            dropTodo(id, category, insertionIndex)
                        }
                    )
                }
                if allowsReordering {
                    Color.clear
                        .frame(height: 20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                                .opacity(isEndDropTargeted ? 0.12 : 0)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.accentColor, lineWidth: isEndDropTargeted ? 2 : 0)
                                }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let payload = items.first, let id = UUID(uuidString: payload) else { return false }
                            dropTodo(id, category, todos.count)
                            return true
                        } isTargeted: { targeted in
                            isEndDropTargeted = targeted
                        }
                }
            }
            .listStyle(.plain)
            .frame(height: 360)
        }
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
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
