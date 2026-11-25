enum ProbeKind: String, CaseIterable, Sendable {
    case startup
    case liveness
    case readiness

    var label: String { rawValue.capitalized }
}
