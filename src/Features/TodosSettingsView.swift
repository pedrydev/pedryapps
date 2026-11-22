import SwiftUI

struct TodosSettingsView: View {
    @Bindable var store: TodosSettingsStore

    var body: some View {
        Form {
            LabeledContent("Due-check interval") {
                Stepper(value: $store.dueCheckIntervalMinutes, in: TodosSettings.minuteBounds) {
                    Text("\(store.dueCheckIntervalMinutes) min")
                }
            }
            Text("This value also sets the lookback when the app launches.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
