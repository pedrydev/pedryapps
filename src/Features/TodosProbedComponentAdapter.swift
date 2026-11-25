import Foundation

struct TodosProbedComponentAdapter {
    let store: TodosStore
    let checkedAt: Date

    init(store: TodosStore, checkedAt: Date = Date()) {
        self.store = store
        self.checkedAt = checkedAt
    }

    var probedComponent: ProbedComponent {
        let errorText = store.storeErrorMessage
        let startupFailed = !store.isBoardLoaded
        let livenessFailed = errorText != nil
        let readinessFailed = !store.isBoardLoaded || store.saveFailurePending
        let results = [
            result(
                kind: .startup,
                outcome: startupFailed ? .failure : .success,
                errorText: startupFailed ? errorText : nil
            ),
            result(
                kind: .liveness,
                outcome: livenessFailed ? .failure : .success,
                errorText: livenessFailed ? errorText : nil
            ),
            result(
                kind: .readiness,
                outcome: readinessFailed ? .failure : .success,
                errorText: readinessFailed ? errorText : nil
            ),
        ]

        let livenessOutcome = results.first(where: { $0.kind == .liveness })?.outcome
        let readinessOutcome = results.first(where: { $0.kind == .readiness })?.outcome
        let healthState: HealthState
        if livenessOutcome == .failure {
            healthState = .unhealthy
        } else if readinessOutcome == .failure {
            healthState = .degraded
        } else {
            healthState = .healthy
        }

        return ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: healthState,
            probeResults: results
        )
    }

    private func result(
        kind: ProbeKind,
        outcome: ProbeOutcome,
        errorText: String?
    ) -> ProbeResult {
        ProbeResult(
            kind: kind,
            outcome: outcome,
            checkedAt: checkedAt,
            errorText: errorText
        )
    }
}
