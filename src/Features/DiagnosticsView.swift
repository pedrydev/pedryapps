import SwiftUI

struct DiagnosticsView: View {
    let probedComponent: ProbedComponent
    @Binding var isExpanded: Bool

    var body: some View {
        Form {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(probedComponent.probeResults) { result in
                    ProbeResultRowView(result: result)
                }
            } label: {
                LabeledContent {
                    Text(verbatim: probedComponent.healthState.label)
                } label: {
                    Text(verbatim: probedComponent.name)
                }
            }
        }
    }
}
