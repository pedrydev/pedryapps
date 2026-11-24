import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let categories: [Category]
    let index: Int
    let allowsDrop: Bool
    let checkOff: (Todo) -> Void
    let moveToCategory: (Todo, Category) -> Void
    let dropTodo: (Todo.ID, Int) -> Void

    @State private var isHovered = false
    @State private var isDropTargeted = false

    var body: some View {
        dragCapableContent
            .contextMenu {
                Menu("Move to Category") {
                    ForEach(categories.filter { $0.id != todo.categoryID }) { category in
                        Button(category.name) {
                            moveToCategory(todo, category)
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private var dragCapableContent: some View {
        if allowsDrop {
            rowContent.draggable(todo.id.uuidString)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(todo.title)
                .font(.body.weight(.semibold))
            HStack {
                Text(todo.doOnDate.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Delete Todo", systemImage: "trash", action: checkOffTodo)
                    .buttonStyle(.borderless)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.red)
                    .help("Permanently removes this Todo")
                    .accessibilityHint("Permanently removes this Todo")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor : Color.primary)
                .opacity(isDropTargeted ? 0.12 : (isHovered ? 0.05 : 0))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: isDropTargeted ? 2 : 0)
                }
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .dropDestination(for: String.self) { items, _ in
            guard allowsDrop, let payload = items.first, let id = UUID(uuidString: payload) else { return false }
            dropTodo(id, index)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }

    private func checkOffTodo() {
        checkOff(todo)
    }
}
