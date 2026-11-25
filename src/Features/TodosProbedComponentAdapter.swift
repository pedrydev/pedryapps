import Foundation

struct TodosProbedComponentAdapter {
    let store: TodosStore
    let checkedAt: Date

    init(store: TodosStore, checkedAt: Date = Date()) {
        self.store = store
        self.checkedAt = checkedAt
    }

    var probedComponent: ProbedComponent {
        let errorText = store.errorMessage
        let hasStoreError = errorText != nil
        return ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: hasStoreError ? .unhealthy : .healthy,
            probeResults: [
                ProbeResult(
                    kind: .startup,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                ),
                ProbeResult(
                    kind: .liveness,
                    outcome: hasStoreError ? .failure : .success,
                    checkedAt: checkedAt,
                    errorText: errorText
                ),
                ProbeResult(
                    kind: .readiness,
                    outcome: hasStoreError ? .failure : .success,
                    checkedAt: checkedAt,
                    errorText: errorText
                ),
            ]
        )
    }
}
