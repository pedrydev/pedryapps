import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let checkOff: (Todo) -> Void

    @State private var isHovered = false

    var body: some View {
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
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }

    private func checkOffTodo() {
        checkOff(todo)
    }
}
