import Foundation

nonisolated struct MCPSettings: Codable, Equatable, Sendable {
    static let `default` = MCPSettings(port: 6174)

    let port: Int
}
