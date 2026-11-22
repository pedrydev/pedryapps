import Foundation

nonisolated enum TimeLeftLabel {
    private static let format: Duration.UnitsFormatStyle = .units(
        allowed: [.hours, .minutes],
        width: .narrow,
        maximumUnitCount: 2,
        zeroValueUnits: .hide,
        fractionalPart: .hide(rounded: .down)
    )

    static func text(from now: Date, to date: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        guard seconds >= 60 else { return "now" }
        return "in \(Duration.seconds(seconds).formatted(format))"
    }
}
