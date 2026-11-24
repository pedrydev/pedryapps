import SwiftUI

struct BoardCategoryView: View {
    let category: Category
    let todos: [Todo]
    @Binding var selectedTodoIDs: Set<Todo.ID>
    let checkOff: (Todo) -> Void
    let setDoOnDate: (DoOnDate, Todo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.headline)
                .lineLimit(1)
            List(selection: $selectedTodoIDs) {
                ForEach(todos) { todo in
                    TodoRow(todo: todo, checkOff: checkOff, setDoOnDate: setDoOnDate)
                }
            }
            .listStyle(.inset)
            .frame(height: 360)
        }
        .frame(width: 280)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}
