import SwiftUI

struct MiniAppSidebarView: View {
    @Binding var selection: MiniApp

    var body: some View {
        VStack(spacing: 8) {
            ForEach(MiniApp.allCases) { miniApp in
                Button(miniApp.name, systemImage: miniApp.symbolName) {
                    selection = miniApp
                }
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
                .font(.title3)
                .frame(minWidth: 32, minHeight: 32)
                .contentShape(Rectangle())
                .disabled(!miniApp.isAvailable)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(miniApp == selection ? Color.accentColor.opacity(0.18) : Color.clear)
                )
                .foregroundStyle(miniApp == selection ? Color.accentColor : Color.secondary)
                .help(miniApp.name)
                .accessibilityLabel(miniApp.name)
                .accessibilityAddTraits(miniApp == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 12)
        .frame(minWidth: 56, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
