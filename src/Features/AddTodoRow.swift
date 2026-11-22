import SwiftUI

struct AddTodoRow: View {
    @Binding var title: String
    @Binding var doOnDate: DoOnDate
    let add: () -> Void

    private var dateBinding: Binding<Date> {
        Binding(
            get: { doOnDate.date },
            set: { doOnDate = DoOnDate($0) }
        )
    }

    var body: some View {
        HStack {
            TextField("Add a Todo", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)
            DatePicker("Do-on date", selection: dateBinding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: 160)
                .help("Do-on date")
            Button("Add", action: add)
                .keyboardShortcut(.defaultAction)
                .disabled(Todo.hasText(title) == false)
        }
        .padding()
    }
}
