import Foundation

enum ProbeEvaluator {
    static func result(
        kind: ProbeKind,
        outcome: ProbeOutcome,
        checkedAt: Date,
        errorText: String?
    ) -> ProbeResult {
        ProbeResult(
            kind: kind,
            outcome: outcome,
            checkedAt: checkedAt,
            errorText: errorText
        )
    }

    static func result(
        kind: ProbeKind,
        isConditionMet: Bool,
        checkedAt: Date,
        errorText: String?
    ) -> ProbeResult {
        result(
            kind: kind,
            outcome: isConditionMet ? .success : .failure,
            checkedAt: checkedAt,
            errorText: isConditionMet ? nil : errorText
        )
    }

    static func healthState(from results: [ProbeResult]) -> HealthState {
        guard !results.isEmpty else { return .starting }

        if results.contains(where: { $0.kind == .liveness && $0.outcome == .failure }) {
            return .unhealthy
        }
        if results.contains(where: { $0.outcome == .unknown }) {
            return .unknown
        }
        if results.contains(where: { $0.kind == .readiness && $0.outcome == .failure }) {
            return .degraded
        }
        guard Set(results.map(\.kind)) == Set(ProbeKind.allCases) else { return .starting }
        return .healthy
    }
}
