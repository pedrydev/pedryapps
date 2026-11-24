import Foundation
import MCP
import OSLog

@MainActor
final class MCPServerController {
    static let defaultPort = 6174

    private let posting: any AgentNotificationPosting
    private let logger = Logger(subsystem: "dev.pedry.PedryApps", category: "MCP")
    private var server: Server?
    private var httpServer: LoopbackHTTPServer?

    init(posting: any AgentNotificationPosting) {
        self.posting = posting
    }

    func start() async {
        stop()
        let port = Self.defaultPort
        let transport = makeMCPHTTPTransport(port: port)
        let server = await makeAgentMCPServer(posting: posting)

        let httpServer: LoopbackHTTPServer
        do {
            httpServer = try LoopbackHTTPServer(
                port: port,
                transport: transport,
                logger: logger
            )
            try await httpServer.start()
        } catch {
            logger.error("MCP server could not bind to port \(port): \(error.localizedDescription)")
            await server.stop()
            return
        }

        do {
            try await server.start(transport: transport)
        } catch {
            logger.error("MCP server could not start: \(error.localizedDescription)")
            httpServer.stop()
            return
        }

        self.server = server
        self.httpServer = httpServer
    }

    func stop() {
        httpServer?.stop()
        httpServer = nil
        if let server {
            Task { await server.stop() }
        }
        self.server = nil
    }
}

@MainActor
final class MCPNotificationPosting: AgentNotificationPosting {
    private let store: NotificationsStore
    private let alertPoster: any SystemAlertPosting

    init(store: NotificationsStore, alertPoster: any SystemAlertPosting) {
        self.store = store
        self.alertPoster = alertPoster
    }

    func post(source: MiniApp, type: NotificationType, title: String, body: String) async {
        store.post(source: source, type: type, title: title, body: body)
        await alertPoster.post(
            identifier: "agent-notification:\(UUID().uuidString)",
            title: title,
            body: body
        )
    }
}
