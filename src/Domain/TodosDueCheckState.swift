import Foundation

nonisolated struct TodosDueCheckState: Codable, Equatable, Sendable {
    var lastReviewedBoundary: Date?
}
