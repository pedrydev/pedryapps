enum ProbeOutcome: String, Sendable {
    case success
    case failure
    case unknown

    var label: String { rawValue.capitalized }
}
