import Foundation
import Testing

@testable import PedryApps

@MainActor
struct DiagnosticsProbeStoreTests {
    @Test func refreshReevaluatesTodosProbes() {
        var evaluations = [
            ProbedComponent(
                id: "todos",
                name: "Todos",
                healthState: .healthy,
                probeResults: []
            ),
            ProbedComponent(
                id: "todos",
                name: "Todos",
                healthState: .unhealthy,
                probeResults: []
            ),
        ]
        let store = DiagnosticsProbeStore { evaluations.removeFirst() }

        #expect(store.todos.healthState == .healthy)

        store.refresh()

        #expect(store.todos.healthState == .unhealthy)
    }

    @Test func refreshUsesTheLatestProbeResults() {
        let checkedAt = Date(timeIntervalSince1970: 1_704_067_200)
        var evaluations = [
            ProbedComponent(
                id: "todos",
                name: "Todos",
                healthState: .healthy,
                probeResults: [
                    ProbeResult(
                        kind: .startup,
                        outcome: .success,
                        checkedAt: checkedAt,
                        errorText: nil
                    )
                ]
            ),
            ProbedComponent(
                id: "todos",
                name: "Todos",
                healthState: .degraded,
                probeResults: [
                    ProbeResult(
                        kind: .readiness,
                        outcome: .failure,
                        checkedAt: checkedAt.addingTimeInterval(30),
                        errorText: "Not ready"
                    )
                ]
            ),
        ]
        let store = DiagnosticsProbeStore { evaluations.removeFirst() }

        store.refresh()

        #expect(store.todos.healthState == .degraded)
        #expect(store.todos.probeResults.first?.kind == .readiness)
        #expect(store.todos.probeResults.first?.errorText == "Not ready")
    }
}
