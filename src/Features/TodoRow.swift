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
                .help("Permanently removes this Todo")
                .accessibilityHint("Permanently removes this Todo")

            Text(todo.title)
            Spacer(minLength: 8)
            DatePicker("Do-on date", selection: dateBinding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: 160)
                .help("Do-on date")
        }
    }

    private func checkOffTodo() {
        checkOff(todo)
    }
}
