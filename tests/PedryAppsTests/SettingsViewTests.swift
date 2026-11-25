import AppKit
import SwiftUI
import Testing
@testable import PedryApps

@Suite(.serialized)
@MainActor
struct SettingsViewTests {
    @Test func settingsShowDiagnosticsTab() throws {
        let directory = try TemporaryDirectory()
        let todosStore = TodosSettingsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "todos-settings.json")
        )
        let mcpStore = MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "mcp-settings.json")
        )

        let rootView = NSHostingView(
            rootView: SettingsView(
                todosSettingsStore: todosStore,
                mcpSettingsStore: mcpStore,
                probedComponent: ProbedComponent(
                    id: "todos",
                    name: "Todos",
                    healthState: .starting,
                    probeResults: []
                )
            )
        )
        rootView.layoutSubtreeIfNeeded()

        let labels = tabLabels(in: rootView)
        #expect(labels.contains("Todos"))
        #expect(labels.contains("MCP"))
        #expect(labels.contains("Diagnostics"))
    }

    private func tabLabels(in view: NSView) -> [String] {
        if let tabView = view as? NSTabView {
            return tabView.tabViewItems.map(\.label)
        }
        return view.subviews.flatMap { tabLabels(in: $0) }
    }
}
