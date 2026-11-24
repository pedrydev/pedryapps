import SwiftUI

struct ManageCategoriesView: View {
    let store: TodosStore

    @Environment(\.dismiss) private var dismiss
    @State private var newCategoryID: Category.ID?
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3.weight(.semibold))
            List {
                ForEach(store.categories) { category in
                    CategoryRow(
                        category: category,
                        todoCount: store.todos(in: category).count,
                        selectsName: category.id == newCategoryID,
                        rename: rename,
                        delete: delete
                    )
                }
                .onMove { store.moveCategories(from: $0, to: $1) }
            }
            .listStyle(.inset)
            HStack {
                Button("Add Category", action: add)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 400, height: 360)
        .padding()
    }

    private func add() {
        newCategoryID = store.addCategory()?.id
        validationMessage = nil
    }

    private func rename(_ category: Category, to name: String) -> String? {
        guard store.renameCategory(category, to: name) else {
            validationMessage = "Use a unique, non-empty name."
            return nil
        }
        if newCategoryID == category.id { newCategoryID = nil }
        validationMessage = nil
        return Category.normalizedName(name)
    }

    private func delete(_ category: Category) {
        guard store.deleteCategory(category) else {
            validationMessage = "The last Category cannot be deleted."
            return
        }
        validationMessage = nil
    }
}

private struct CategoryRow: View {
    let category: Category
    let todoCount: Int
    let selectsName: Bool
    let rename: (Category, String) -> String?
    let delete: (Category) -> Void

    @State private var draft: String

    init(
        category: Category,
        todoCount: Int,
        selectsName: Bool,
        rename: @escaping (Category, String) -> String?,
        delete: @escaping (Category) -> Void
    ) {
        self.category = category
        self.todoCount = todoCount
        self.selectsName = selectsName
        self.rename = rename
        self.delete = delete
        _draft = State(initialValue: category.name)
    }

    var body: some View {
        HStack(spacing: 8) {
            CategoryNameField(name: $draft, selectsOnAppear: selectsName) { name in
                draft = rename(category, name) ?? category.name
            } cancel: {
                draft = category.name
            }
            if todoCount > 0 {
                Text(todoCount, format: .number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Delete Category", systemImage: "trash") {
                delete(category)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Delete Category")
            .disabled(todoCount > 0)
        }
    }
}
