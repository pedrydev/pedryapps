struct ProbedComponent: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let healthState: HealthState
}
