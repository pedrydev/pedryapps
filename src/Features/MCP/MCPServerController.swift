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

struct MCPNotificationPosting: AgentNotificationPosting {
    private let post: @MainActor @Sendable (MiniApp, NotificationType, String, String) -> Void

    init(store: NotificationsStore) {
        post = { source, type, title, body in
            store.post(source: source, type: type, title: title, body: body)
        }
    }

    func post(source: MiniApp, type: NotificationType, title: String, body: String) async {
        await MainActor.run {
            post(source, type, title, body)
        }
    }
}
