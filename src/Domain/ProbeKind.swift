enum ProbeKind: String, Sendable {
    case startup
    case liveness
    case readiness

    var label: String { rawValue.capitalized }
}
