import AppKit
import SwiftUI
import Testing
@testable import PedryApps

@Suite(.serialized)
@MainActor
struct MCPSettingsViewTests {
    @Test func mcpSettingsShowOnePortField() throws {
        let directory = try TemporaryDirectory()
        let store = MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "mcp-settings.json")
        )

        let rootView = NSHostingView(rootView: MCPSettingsView(store: store))
        rootView.layoutSubtreeIfNeeded()

        let fields = textFields(in: rootView)
        #expect(fields.count == 1)
        #expect(fields.first?.stringValue == "6174")
    }

    @Test func invalidPortHasValidationMessageAndDoesNotPersist() throws {
        let directory = try TemporaryDirectory()
        let store = MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "mcp-settings.json")
        )

        #expect(MCPSettingsView.validationMessage(for: "80") == "Port must be between 1024 and 65535.")
        #expect(MCPSettingsView.validationMessage(for: "abc") == "Enter a whole number between 1024 and 65535.")
        #expect(MCPSettingsView.validationMessage(for: "6174") == nil)
        #expect(store.setPort(80) == false)
        #expect(store.settings.port == 6174)
    }

    private func textFields(in view: NSView) -> [NSTextField] {
        let direct = (view as? NSTextField).map { [$0] } ?? []
        return direct + view.subviews.flatMap { textFields(in: $0) }
    }
}
