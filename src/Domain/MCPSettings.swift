import Foundation

nonisolated struct MCPSettings: Codable, Equatable, Sendable {
    static let `default` = MCPSettings(port: 6174)
    static let portRangeDescription = "\(portRange.lowerBound) and \(portRange.upperBound)"
    private static let portRange = 1024...65535

    let port: Int

    static func isValidPort(_ port: Int) -> Bool {
        portRange.contains(port)
    }

    init(port: Int) {
        self.port = port
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let port = try container.decode(Int.self, forKey: .port)
        guard Self.isValidPort(port) else {
            throw DecodingError.dataCorruptedError(forKey: .port, in: container, debugDescription: "Invalid port")
        }
        self.port = port
    }

    private enum CodingKeys: String, CodingKey {
        case port
    }
}
