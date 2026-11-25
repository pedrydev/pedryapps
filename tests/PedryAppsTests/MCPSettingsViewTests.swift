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

    private func textFields(in view: NSView) -> [NSTextField] {
        let direct = (view as? NSTextField).map { [$0] } ?? []
        return direct + view.subviews.flatMap { textFields(in: $0) }
    }
}
