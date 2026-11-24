import Darwin
import Foundation
import MCP
import OSLog
import Testing

@testable import PedryApps

struct MCPAgentServerTests {
    @Test func toolDiscoveryAdvertisesOnlySendNotification() async throws {
        let harness = try await MCPTestHarness(posting: StubAgentNotificationPosting())

        let (tools, _) = try await harness.client.listTools()
        let tool = try #require(tools.first)

        #expect(tools.count == 1)
        #expect(tool.name == "send_notification")
        await harness.stop()
    }

    @Test func toolSchemaRequiresTitleBodyAndType() async throws {
        let harness = try await MCPTestHarness(posting: StubAgentNotificationPosting())

        let (tools, _) = try await harness.client.listTools()
        let tool = try #require(tools.first)
        let schema = try #require(tool.inputSchema.objectValue)
        let required = try #require(schema["required"]?.arrayValue?.compactMap { try? $0.stringValue })
        let properties = try #require(schema["properties"]?.objectValue)
        let typeSchema = try #require(properties["type"]?.objectValue)
        let typeValues = try #require(typeSchema["enum"]?.arrayValue?.compactMap { try? $0.stringValue })

        #expect(Set(required) == ["title", "body", "type"])
        #expect(properties["delay"] == nil)
        #expect(typeValues == ["information", "attentionRequest"])
        await harness.stop()
    }

    @Test func toolDescriptionExplainsBothNotificationTypes() async throws {
        let harness = try await MCPTestHarness(posting: StubAgentNotificationPosting())

        let (tools, _) = try await harness.client.listTools()
        let tool = try #require(tools.first)
        let description = try #require(tool.description)
        let schema = try #require(tool.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let typeSchema = try #require(properties["type"]?.objectValue)
        let typeDescription = try #require(typeSchema["description"]?.stringValue)

        #expect(description.contains("Information"))
        #expect(description.contains("Attention request"))
        #expect(typeDescription.contains("something that already happened"))
        #expect(typeDescription.contains("needs further action"))
        await harness.stop()
    }

    @Test func serverDeclaresSDKProtocolVersion() async throws {
        let harness = try await MCPTestHarness(posting: StubAgentNotificationPosting())

        #expect(harness.protocolVersion == Version.latest)
        await harness.stop()
    }

    @Test func validCallPostsNotificationAttributedToNotifications() async throws {
        let posting = StubAgentNotificationPosting()
        let harness = try await MCPTestHarness(posting: posting)

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: [
                "title": "Build finished",
                "body": "The nightly build is ready.",
                "type": "information",
            ]
        )

        #expect(result.isError != true)
        let posts = await posting.posts
        #expect(
            posts == [
                .init(
                    source: .notifications,
                    type: .information,
                    title: "Build finished",
                    body: "The nightly build is ready."
                )
            ])
        await harness.stop()
    }

    @Test @MainActor func successfulCallPostsInboxNotificationAndSystemAlert() async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        let center = FakeSystemAlertCenter()
        let harness = try await makeAgentHarness(store: store, center: center)

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: [
                "title": "Build finished",
                "body": "The nightly build is ready.",
                "type": "information",
            ]
        )

        #expect(result.isError != true)
        #expect(store.notifications.count == 1)
        #expect(store.notifications.first?.title == "Build finished")
        #expect(center.addAttempts == 1)
        let alert = try #require(center.requests.first)
        #expect(alert.identifier.hasPrefix("agent-notification:"))
        #expect(alert.title == "Build finished")
        #expect(alert.body == "The nightly build is ready.")
        await harness.stop()
    }

    @Test @MainActor func firstRunRequestsAuthorizationBeforeSystemAlert() async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        let center = FakeSystemAlertCenter()
        center.authorization = .notDetermined
        let harness = try await MCPTestHarness(
            posting: MCPNotificationPosting(store: store, alertPoster: SystemAlertPoster(center: center))
        )

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: [
                "title": "Authorization check",
                "body": "The first call requests authorization.",
                "type": "information",
            ]
        )

        #expect(result.isError != true)
        #expect(center.authorizationRequests == 1)
        #expect(center.requests.count == 1)
        #expect(store.notifications.count == 1)
        await harness.stop()
    }

    @Test(arguments: [SystemAlertAuthorizationStatus.denied, .notDetermined])
    @MainActor func deniedAlertAuthorizationKeepsInboxEntryAndSucceeds(
        initialStatus: SystemAlertAuthorizationStatus
    ) async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        let center = FakeSystemAlertCenter()
        center.authorization = initialStatus
        center.authorizationAfterRequest = .denied
        let harness = try await MCPTestHarness(
            posting: MCPNotificationPosting(store: store, alertPoster: SystemAlertPoster(center: center))
        )

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: [
                "title": "Denied alert",
                "body": "The Inbox entry must survive a denied alert.",
                "type": "attentionRequest",
            ]
        )

        #expect(result.isError != true)
        #expect(store.notifications.count == 1)
        #expect(store.notifications.first?.title == "Denied alert")
        #expect(center.addAttempts == 0)
        #expect(center.requests.isEmpty)
        #expect(center.authorizationRequests == (initialStatus == .notDetermined ? 1 : 0))
        await harness.stop()
    }

    @Test func missingTypeRejectsCallWithoutPosting() async throws {
        let posting = StubAgentNotificationPosting()
        let harness = try await MCPTestHarness(posting: posting)

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: ["title": "Missing type", "body": "No type was supplied."]
        )

        #expect(result.isError == true)
        let posts = await posting.posts
        #expect(posts.isEmpty)
        await harness.stop()
    }

    @Test func unknownTypeRejectsCallWithoutPosting() async throws {
        let posting = StubAgentNotificationPosting()
        let harness = try await MCPTestHarness(posting: posting)

        let result = try await harness.client.callTool(
            name: "send_notification",
            arguments: [
                "title": "Unknown type",
                "body": "The type is not supported.",
                "type": "urgent",
            ]
        )

        #expect(result.isError == true)
        let posts = await posting.posts
        #expect(posts.isEmpty)
        await harness.stop()
    }

    @Test func unexpectedOriginIsRejected() async {
        let transport = makeMCPHTTPTransport(port: 6174)
        let request = HTTPRequest(
            method: "POST",
            headers: [
                "Host": "127.0.0.1:6174",
                "Origin": "http://evil.example",
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: Data(#"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#.utf8),
            path: "/mcp"
        )

        let response = await transport.handleRequest(request)

        #expect(response.statusCode == 403)
    }

    @Test func postingAdapterCreatesInboxNotificationAndUpdatesBadge() async throws {
        let directory = try TemporaryDirectory()
        let postedAt = try fixtureDate(2030, 1, 2, at: 10, minute: 30, calendar: utcCalendar())
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json"),
            now: { postedAt }
        )
        let posting = MCPNotificationPosting(
            store: store,
            alertPoster: SystemAlertPoster(center: FakeSystemAlertCenter())
        )

        await posting.post(
            source: .notifications,
            type: .attentionRequest,
            title: "Review deployment",
            body: "The release needs approval"
        )

        let notification = try #require(store.notifications.first)
        #expect(notification.source == .notifications)
        #expect(notification.type == .attentionRequest)
        #expect(notification.title == "Review deployment")
        #expect(notification.body == "The release needs approval")
        #expect(notification.postedAt == postedAt)
        #expect(NotificationsStore.lifetime == 6 * 60 * 60)
        #expect(store.unreadCount == 1)
        let overview = MenuBarNotificationsOverview.make(from: store.notifications, now: postedAt)
        #expect(overview.unreadCount == 1)
        #expect(overview.unread.first?.title == "Review deployment")
    }

    @Test func loopbackHTTPServerHandlesInitializeAndToolCall() async throws {
        let port = try availableLoopbackPort()
        let posting = StubAgentNotificationPosting()
        let transport = makeMCPHTTPTransport(port: port)
        let server = await makeAgentMCPServer(posting: posting)
        let httpServer = try LoopbackHTTPServer(
            port: port,
            transport: transport,
            logger: Logger(subsystem: "dev.pedry.PedryApps.tests", category: "MCP")
        )
        try await httpServer.start()
        do {
            try await server.start(transport: transport)
        } catch {
            httpServer.stop()
            throw error
        }
        defer {
            httpServer.stop()
            Task { await server.stop() }
        }

        let initialize = try await postJSON(
            [
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": [
                    "protocolVersion": Version.latest,
                    "capabilities": [:],
                    "clientInfo": ["name": "PedryAppsTests", "version": "1"],
                ],
            ],
            to: port
        )
        #expect(initialize.status == 200)
        let initializeResult = try #require(initialize.body["result"] as? [String: Any])
        #expect(initializeResult["protocolVersion"] as? String == Version.latest)

        let tools = try await postJSON(
            ["jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": [:]],
            to: port,
            protocolVersion: Version.latest
        )
        #expect(tools.status == 200)
        let toolsResult = try #require(tools.body["result"] as? [String: Any])
        let listedTools = try #require(toolsResult["tools"] as? [[String: Any]])
        #expect(listedTools.compactMap { $0["name"] as? String } == ["send_notification"])

        let call = try await postJSON(
            [
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": [
                    "name": "send_notification",
                    "arguments": [
                        "title": "Loopback test",
                        "body": "The loopback transport responded.",
                        "type": "information",
                    ],
                ],
            ],
            to: port,
            protocolVersion: Version.latest
        )
        #expect(call.status == 200)
        let callResult = try #require(call.body["result"] as? [String: Any])
        let content = try #require(callResult["content"] as? [[String: Any]])
        #expect(callResult["isError"] as? Bool != true)
        #expect(content.first?["text"] as? String == "Notification posted to the Inbox.")

        let posts = await posting.posts
        #expect(posts.count == 1)
        #expect(posts.first?.title == "Loopback test")
    }
}

@MainActor
private func makeAgentHarness(
    store: NotificationsStore,
    center: FakeSystemAlertCenter
) async throws -> MCPTestHarness {
    try await MCPTestHarness(
        posting: MCPNotificationPosting(store: store, alertPoster: SystemAlertPoster(center: center))
    )
}

private struct MCPTestHarness {
    let client: Client
    let protocolVersion: String
    private let server: Server

    init(posting: any AgentNotificationPosting) async throws {
        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        server = await makeAgentMCPServer(posting: posting)
        client = Client(name: "PedryAppsTests", version: "1.0")
        try await server.start(transport: serverTransport)
        let initializeResult = try await client.connect(transport: clientTransport)
        protocolVersion = initializeResult.protocolVersion
    }

    func stop() async {
        await client.disconnect()
        await server.stop()
    }
}

private actor StubAgentNotificationPosting: AgentNotificationPosting {
    struct Post: Equatable {
        let source: MiniApp
        let type: NotificationType
        let title: String
        let body: String
    }

    private(set) var posts: [Post] = []

    func post(source: MiniApp, type: NotificationType, title: String, body: String) async {
        posts.append(Post(source: source, type: type, title: title, body: body))
    }
}

private func availableLoopbackPort() throws -> Int {
    let fileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    guard fileDescriptor >= 0 else {
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
    }
    defer { close(fileDescriptor) }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = 0
    address.sin_addr.s_addr = inet_addr("127.0.0.1")

    let bindResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            bind(fileDescriptor, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    guard bindResult == 0 else {
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
    }

    var length = socklen_t(MemoryLayout<sockaddr_in>.size)
    var boundAddress = sockaddr_in()
    let nameResult = withUnsafeMutablePointer(to: &boundAddress) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            getsockname(fileDescriptor, sockaddrPointer, &length)
        }
    }
    guard nameResult == 0 else {
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
    }

    let port = Int(UInt16(bigEndian: boundAddress.sin_port))
    guard port > 0 else {
        throw NSError(domain: "PedryAppsTests", code: 1, userInfo: nil)
    }
    return port
}

private func postJSON(
    _ message: [String: Any],
    to port: Int,
    protocolVersion: String? = nil
) async throws -> (status: Int, body: [String: Any]) {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 5
    configuration.timeoutIntervalForResource = 5
    let session = URLSession(configuration: configuration)
    defer { session.invalidateAndCancel() }

    var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/mcp")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("http://127.0.0.1:\(port)", forHTTPHeaderField: "Origin")
    if let protocolVersion {
        request.setValue(protocolVersion, forHTTPHeaderField: "MCP-Protocol-Version")
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: message)

    let (data, response) = try await session.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
    let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    return (status, body)
}
