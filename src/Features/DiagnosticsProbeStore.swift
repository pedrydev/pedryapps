import Observation

@MainActor
@Observable
final class DiagnosticsProbeStore {
    private(set) var todos: ProbedComponent

    private let evaluate: () -> ProbedComponent

    init(evaluate: @escaping () -> ProbedComponent) {
        self.evaluate = evaluate
        todos = evaluate()
    }

    func refresh() {
        todos = evaluate()
    }
}
