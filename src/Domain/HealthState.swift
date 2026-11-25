enum HealthState: String, CaseIterable, Sendable {
    case starting
    case healthy
    case degraded
    case unhealthy
    case unknown

    var label: String {
        rawValue.capitalized
    }
}
