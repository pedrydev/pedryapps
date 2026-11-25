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

    @Test(arguments: [1023, 65536, -1, 0])
    func invalidPortIsIgnoredAndNotPersisted(_ port: Int) throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<MCPSettings>(directory: directory.url, filename: "mcp-settings.json")
        let store = MCPSettingsStore(documentStore: documentStore)

        #expect(!store.setPort(port))
        #expect(store.settings.port == 6174)
        #expect(try documentStore.load() == nil)
    }

    @Test(arguments: [1024, 65535])
    func boundaryPortsAreAccepted(_ port: Int) throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        #expect(store.setPort(port))
        #expect(store.settings.port == port)
    }

    @Test func invalidStoredPortFallsBackToDefault() throws {
        let directory = try TemporaryDirectory()
        let url = directory.url.appendingPathComponent("mcp-settings.json")
        try Data(#"{"port":80}"#.utf8).write(to: url)

        let store = makeStore(in: directory.url)

        #expect(store.settings.port == 6174)
    }

    private func makeStore(in directory: URL) -> MCPSettingsStore {
        MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "mcp-settings.json")
        )
    }
}
