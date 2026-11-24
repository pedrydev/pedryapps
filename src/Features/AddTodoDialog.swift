import SwiftUI

struct AddTodoDialog: View {
    let category: Category
    @Binding var title: String
    @Binding var doOnDate: DoOnDate
    let errorMessage: String?
    let add: () -> Bool
    let cancel: () -> Void

    @FocusState private var isTitleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var dateBinding: Binding<Date> {
        Binding(
            get: { doOnDate.date },
            set: { doOnDate = DoOnDate($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Todo to \(category.name)")
                .font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .focused($isTitleFocused)
                .onSubmit(submit)
            DoOnDatePicker(date: dateBinding, preventsPast: true)
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel", action: dismissDialog)
                Button("Add", action: submit)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { isTitleFocused = true }
    }

    private func submit() {
        guard add() else { return }
        dismiss()
    }

    private func dismissDialog() {
        cancel()
        dismiss()
    }
}
