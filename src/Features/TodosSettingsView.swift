import SwiftUI

struct TodosSettingsView: View {
    @Bindable var store: TodosSettingsStore

    var body: some View {
        Form {
            LabeledContent("Due-check interval") {
                Stepper(
                    value: $store.dueCheckIntervalMinutes,
                    in: TodosSettings.minuteBounds,
                    step: TodosSettings.minuteStep
                ) {
                    Text("\(store.dueCheckIntervalMinutes) min")
                }
            }
            Text("Each check reviews the due-check window that just ended.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
