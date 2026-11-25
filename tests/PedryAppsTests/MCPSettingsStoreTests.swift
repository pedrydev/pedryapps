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

    @Test func portChangeRestartsMCPServer() async throws {
        let environment = try makePortChangeEnvironment()
        defer { environment.cleanup() }
        environment.delegate.installMCPPortChangeHandler()

        await confirmation { confirm in
            environment.controller.onRestart = { port in
                #expect(port == 7000)
                confirm()
            }
            #expect(environment.store.setPort(7000))
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(environment.controller.events == ["restart:7000"])
    }

    @Test func unchangedPortDoesNotRestartMCPServer() throws {
        let environment = try makePortChangeEnvironment()
        defer { environment.cleanup() }
        environment.delegate.installMCPPortChangeHandler()

        #expect(environment.store.setPort(6174))
        #expect(environment.controller.events.isEmpty)
    }

    @Test func invalidPortDoesNotRestartMCPServer() throws {
        let environment = try makePortChangeEnvironment()
        defer { environment.cleanup() }
        environment.delegate.installMCPPortChangeHandler()

        #expect(!environment.store.setPort(80))
        #expect(environment.controller.events.isEmpty)
    }

    private func makeStore(in directory: URL) -> MCPSettingsStore {
        MCPSettingsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "mcp-settings.json")
        )
    }

    private func makePortChangeEnvironment() throws -> (
        store: MCPSettingsStore,
        controller: RecordingMCPServerController,
        delegate: MenuBarAppDelegate,
        directory: TemporaryDirectory,
        cleanup: () -> Void
    ) {
        let suiteName = "MCPSettings.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let controller = RecordingMCPServerController()
        let delegate = MenuBarAppDelegate(
            selectionStore: MiniAppSelectionStore(userDefaults: defaults),
            notificationsStore: NotificationsStore(
                documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
            ),
            mcpSettingsStore: store,
            mcpServerController: controller
        )
        return (
            store,
            controller,
            delegate,
            directory,
            {
                defaults.removePersistentDomain(forName: suiteName)
            }
        )
    }
}

@MainActor
private final class RecordingMCPServerController: MCPServerControlling {
    private(set) var events: [String] = []
    var onRestart: ((Int) -> Void)?

    func start(port: Int) async {
        events.append("start:\(port)")
    }

    func restart(port: Int) async {
        events.append("restart:\(port)")
        onRestart?(port)
    }

    func stop() {
        events.append("stop")
    }
}
