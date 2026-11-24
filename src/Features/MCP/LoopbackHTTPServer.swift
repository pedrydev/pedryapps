import Foundation
import MCP
import Network
import OSLog

private enum LoopbackHTTPServerError: Error {
    case invalidPort(Int)
}

func makeMCPHTTPTransport(port: Int) -> StatelessHTTPServerTransport {
    StatelessHTTPServerTransport(
        validationPipeline: StandardValidationPipeline(validators: [
            OriginValidator.localhost(port: port),
            AcceptHeaderValidator(mode: .jsonOnly),
            ContentTypeValidator(),
            ProtocolVersionValidator(),
        ])
    )
}

nonisolated final class LoopbackHTTPServer: @unchecked Sendable {
    nonisolated static let host = "127.0.0.1"
    nonisolated static let path = "/mcp"

    private let listener: NWListener
    private let transport: StatelessHTTPServerTransport
    private let logger: Logger
    private let startLock = NSLock()
    private let connectionsLock = NSLock()
    private var startResolved = false
    private var connections: [ObjectIdentifier: LoopbackHTTPConnection] = [:]

    init(port: Int, transport: StatelessHTTPServerTransport, logger: Logger) throws {
        guard (1...65535).contains(port), let endpointPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            throw LoopbackHTTPServerError.invalidPort(port)
        }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: .ipv4(.loopback),
            port: endpointPort
        )
        self.listener = try NWListener(using: parameters)
        self.transport = transport
        self.logger = logger
    }

    func start() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                Task { await self.handleListenerState(state) }
                switch state {
                case .ready:
                    self.resolveStart(.success(()), continuation: continuation)
                case .failed(let error):
                    self.resolveStart(.failure(error), continuation: continuation)
                case .cancelled:
                    self.resolveStart(.failure(CancellationError()), continuation: continuation)
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { await self?.handleConnection(connection) }
            }
            listener.start(queue: .global())
        }
    }

    func stop() {
        listener.cancel()
    }

    nonisolated private func resolveStart(
        _ result: Result<Void, Error>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        startLock.lock()
        defer { startLock.unlock() }
        guard !startResolved else { return }
        startResolved = true
        switch result {
        case .success:
            continuation.resume()
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    private func handleListenerState(_ state: NWListener.State) async {
        switch state {
        case .ready:
            logger.info("MCP server listening on \(Self.host):\(self.listener.port?.rawValue ?? 0)")
        case .failed(let error):
            logger.error("MCP server failed to bind: \(error.localizedDescription)")
        case .cancelled:
            logger.info("MCP server stopped")
        default:
            break
        }
    }

    private func handleConnection(_ connection: NWConnection) async {
        let handler = LoopbackHTTPConnection(
            connection: connection,
            transport: transport,
            logger: logger,
            onFinish: { [weak self] in
                self?.removeConnection(connection)
            }
        )
        storeConnection(handler, for: connection)
        await handler.start()
    }

    nonisolated private func storeConnection(
        _ handler: LoopbackHTTPConnection,
        for connection: NWConnection
    ) {
        connectionsLock.lock()
        connections[ObjectIdentifier(connection)] = handler
        connectionsLock.unlock()
    }

    nonisolated private func removeConnection(_ connection: NWConnection) {
        connectionsLock.lock()
        connections.removeValue(forKey: ObjectIdentifier(connection))
        connectionsLock.unlock()
    }
}

private actor LoopbackHTTPConnection {
    private static let maximumRequestSize = 1024 * 1024

    private let connection: NWConnection
    private let transport: StatelessHTTPServerTransport
    private let logger: Logger
    private let onFinish: @Sendable () -> Void
    private var buffer = Data()
    private var didFinish = false

    init(
        connection: NWConnection,
        transport: StatelessHTTPServerTransport,
        logger: Logger,
        onFinish: @escaping @Sendable () -> Void
    ) {
        self.connection = connection
        self.transport = transport
        self.logger = logger
        self.onFinish = onFinish
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            Task { await self?.handleConnectionState(state) }
        }
        connection.start(queue: .global())
        receive()
    }

    private func handleConnectionState(_ state: NWConnection.State) async {
        switch state {
        case .failed(let error):
            logger.debug("MCP connection failed: \(error.localizedDescription)")
            finish()
        case .cancelled:
            finish()
        default:
            break
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish()
        connection.cancel()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            Task { await self?.handleReceive(data: data, isComplete: isComplete, error: error) }
        }
    }

    private func handleReceive(data: Data?, isComplete: Bool, error: NWError?) async {
        if let data {
            buffer.append(data)
        }

        if let error {
            logger.debug("MCP connection read failed: \(error.localizedDescription)")
            finish()
            return
        }

        if let request = parseRequest(from: buffer) {
            await respond(to: request)
            return
        }

        if buffer.count > Self.maximumRequestSize {
            let response = HTTPResponse.error(
                statusCode: 413,
                .invalidRequest("Request too large")
            )
            await write(response)
            return
        }

        if isComplete {
            finish()
            return
        }

        receive()
    }

    private func parseRequest(from data: Data) -> HTTPRequest? {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerEnd = data.range(of: separator) else { return nil }
        guard let headerText = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else {
            return nil
        }

        let lines = headerText.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else { return nil }
        let requestParts = requestLine.split(separator: " ")
        guard requestParts.count == 3 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let pair = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.count == 2 else { continue }
            let name = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
            headers[name] = pair[1].trimmingCharacters(in: .whitespaces)
        }

        let bodyStart = headerEnd.upperBound
        let contentLength = Int(headers["content-length"] ?? "0") ?? 0
        guard contentLength >= 0, data.count >= bodyStart + contentLength else { return nil }
        let body = contentLength > 0 ? Data(data[bodyStart..<(bodyStart + contentLength)]) : nil

        return HTTPRequest(
            method: String(requestParts[0]),
            headers: headers,
            body: body,
            path: String(requestParts[1])
        )
    }

    private func respond(to request: HTTPRequest) async {
        let path = request.path?.split(separator: "?").first.map(String.init) ?? ""
        let response: HTTPResponse
        if path == LoopbackHTTPServer.path {
            response = await transport.handleRequest(request)
        } else {
            response = .error(statusCode: 404, .invalidRequest("Not Found"))
        }
        await write(response)
    }

    private func write(_ response: HTTPResponse) async {
        let body = response.bodyData ?? Data()
        var header = "HTTP/1.1 \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))\r\n"
        for (name, value) in response.headers {
            header += "\(name): \(value)\r\n"
        }
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n\r\n"

        var data = Data(header.utf8)
        data.append(body)
        connection.send(
            content: data,
            completion: .contentProcessed({ [weak self] _ in
                Task { await self?.finish() }
            }))
    }
}
