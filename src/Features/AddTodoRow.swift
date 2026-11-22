import SwiftUI

struct AddTodoRow: View {
    @Binding var title: String
    @Binding var doOnDate: DoOnDate
    var isFocused: FocusState<Bool>.Binding
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
                .focused(isFocused)
                .onSubmit(add)
            DoOnDatePicker(date: dateBinding, preventsPast: true)
        }
        .padding()
    }
}
