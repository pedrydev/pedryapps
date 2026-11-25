import Foundation

struct ProbeResult: Identifiable, Equatable, Sendable {
    let kind: ProbeKind
    let outcome: ProbeOutcome
    let checkedAt: Date?
    let errorText: String?

    var id: ProbeKind { kind }
}
