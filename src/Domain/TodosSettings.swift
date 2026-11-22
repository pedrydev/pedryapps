import Foundation

nonisolated struct TodosSettings: Codable, Equatable, Sendable {
    static let `default` = TodosSettings(dueCheckIntervalSeconds: 300)
    static let minuteBounds = 5...60
    static let minuteStep = 5

    let dueCheckIntervalSeconds: Int

    var dueCheckIntervalMinutes: Int { Self.snappedMinutes(from: dueCheckIntervalSeconds / 60) }

    var snappedDueCheckIntervalSeconds: Int { dueCheckIntervalMinutes * 60 }

    static func snappedMinutes(from minutes: Int) -> Int {
        let snapped = ((minutes + minuteStep / 2) / minuteStep) * minuteStep
        return min(max(snapped, minuteBounds.lowerBound), minuteBounds.upperBound)
    }

    static func seconds(fromMinutes minutes: Int) -> Int? {
        guard minuteBounds.contains(minutes), minutes.isMultiple(of: minuteStep) else { return nil }
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
