import SwiftUI

struct ToolbarActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .disabled(isDisabled)
    }
}
