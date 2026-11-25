import Foundation
import Testing
@testable import PedryApps

@MainActor
struct MCPSettingsStoreTests {
    @Test func missingSettingsDocumentUsesDefaultPort() throws {
        let directory = try TemporaryDirectory()

        let store = makeStore(in: directory.url)

        #expect(store.settings.port == 6174)
    }

    @Test func changingPortPersistsAndRestores() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        #expect(store.setPort(7000))
        let reloaded = makeStore(in: directory.url)

        #expect(store.settings.port == 7000)
        #expect(reloaded.settings.port == 7000)
    }

    private func makeStore(in directory: URL) -> MCPSettingsStore {
        MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "mcp-settings.json")
        )
    }
}
