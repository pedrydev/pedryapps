enum MiniApp: String, Codable, CaseIterable, Identifiable {
    case todos
    case notifications

    var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .todos: "Todos"
        case .notifications: "Notifications"
        }
    }

    var symbolName: String {
        switch self {
        case .todos: "checklist"
        case .notifications: "bell"
        }
    }
}
