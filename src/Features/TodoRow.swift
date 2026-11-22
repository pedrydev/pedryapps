import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let checkOff: (Todo) -> Void
    let setDoOnDate: (DoOnDate, Todo) -> Void

    private var dateBinding: Binding<Date> {
        Binding(
            get: { todo.doOnDate.date },
            set: { setDoOnDate(DoOnDate($0), todo) }
        )
    }

    var body: some View {
        HStack {
            Button("Check off", systemImage: "circle", action: checkOffTodo)
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
                .help("Permanently removes this Todo")
                .accessibilityHint("Permanently removes this Todo")

            Text(todo.title)
            Spacer(minLength: 8)
            DoOnDatePicker(date: dateBinding)
        }
    }

    private func checkOffTodo() {
        checkOff(todo)
    }
}
