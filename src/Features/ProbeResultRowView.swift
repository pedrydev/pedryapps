import SwiftUI

struct ProbeResultRowView: View {
    let result: ProbeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent {
                Text(verbatim: result.outcome.label)
            } label: {
                Text(verbatim: result.kind.label)
            }
            LabeledContent("Last check") {
                if let checkedAt = result.checkedAt {
                    Text(verbatim: checkedAt.formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text(verbatim: "Not checked")
                }
            }
            if let errorText = result.errorText {
                Text(verbatim: errorText)
            }
        }
    }
}
