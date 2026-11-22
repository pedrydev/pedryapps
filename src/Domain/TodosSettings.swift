import Foundation

nonisolated struct TodosSettings: Codable, Equatable, Sendable {
    static let `default` = TodosSettings(dueCheckIntervalSeconds: 300)
    static let minuteBounds = 1...60

    let dueCheckIntervalSeconds: Int

    var dueCheckIntervalMinutes: Int { dueCheckIntervalSeconds / 60 }

    static func seconds(fromMinutes minutes: Int) -> Int? {
        guard minuteBounds.contains(minutes) else { return nil }
        return minutes * 60
    }

    init(dueCheckIntervalSeconds: Int) {
        self.dueCheckIntervalSeconds = dueCheckIntervalSeconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Int.self, forKey: .dueCheckIntervalSeconds)
        guard seconds > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .dueCheckIntervalSeconds,
                in: container,
                debugDescription: "Due-check interval must be a positive number of seconds."
            )
        }
        dueCheckIntervalSeconds = seconds
    }

    private enum CodingKeys: String, CodingKey {
        case dueCheckIntervalSeconds
    }
}
