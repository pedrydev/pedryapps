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
        let results = [
            ProbeEvaluator.result(
                kind: .startup,
                isConditionMet: store.isBoardLoaded,
                checkedAt: checkedAt,
                errorText: errorText
            ),
            ProbeEvaluator.result(
                kind: .liveness,
                isConditionMet: errorText == nil,
                checkedAt: checkedAt,
                errorText: errorText
            ),
            ProbeEvaluator.result(
                kind: .readiness,
                isConditionMet: store.isBoardLoaded && !store.saveFailurePending,
                checkedAt: checkedAt,
                errorText: errorText
            ),
        ]

        return ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: ProbeEvaluator.healthState(from: results),
            probeResults: results
        )
    }
}
