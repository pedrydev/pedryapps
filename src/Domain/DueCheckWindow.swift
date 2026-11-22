import Foundation

nonisolated struct DueCheckWindow {
    let start: Date
    let end: Date

    static func ending(
        at boundary: Date,
        interval: TimeInterval,
        lastReviewedBoundary: Date?
    ) -> DueCheckWindow {
        DueCheckWindow(
            start: lastReviewedBoundary ?? boundary.addingTimeInterval(-interval),
            end: boundary
        )
    }

    func contains(_ date: Date) -> Bool {
        date > start && date <= end
    }
}
