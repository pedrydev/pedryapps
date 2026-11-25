import SwiftUI

struct MCPSettingsView: View {
    let store: MCPSettingsStore
    @State private var portText: String

    init(store: MCPSettingsStore) {
        self.store = store
        _portText = State(initialValue: String(store.settings.port))
    }

    var body: some View {
        Form {
            LabeledContent("Port") {
                TextField("Port", text: $portText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit(commitPort)
            }
            Text("The MCP server listens on this loopback port.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func commitPort() {
        guard let port = Int(portText) else { return }
        if !store.setPort(port) {
            portText = String(store.settings.port)
        }
    }
}
