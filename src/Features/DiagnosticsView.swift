import SwiftUI

struct DiagnosticsView: View {
    let probedComponent: ProbedComponent

    var body: some View {
        Form {
            LabeledContent {
                Text(verbatim: probedComponent.healthState.label)
            } label: {
                Text(verbatim: probedComponent.name)
            }
        }
    }
}
