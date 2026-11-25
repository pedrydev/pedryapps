import SwiftUI

struct MCPSettingsView: View {
    let store: MCPSettingsStore
    @State private var portText: String
    @State private var validationMessage: String?

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
                    .onChange(of: portText) { _, newValue in
                        validationMessage = Self.validationMessage(for: newValue)
                    }
                    .onSubmit(commitPort)
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("The MCP server listens on this loopback port.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func commitPort() {
        guard let port = Int(portText), MCPSettings.isValidPort(port) else { return }
        if !store.setPort(port) {
            portText = String(store.settings.port)
        }
    }

    static func validationMessage(for text: String) -> String? {
        guard let port = Int(text) else {
            return "Enter a whole number between \(MCPSettings.portRangeDescription)."
        }
        guard MCPSettings.isValidPort(port) else {
            return "Port must be between \(MCPSettings.portRangeDescription)."
        }
        return nil
    }
}
