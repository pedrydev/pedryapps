enum MiniApp: String, Codable, CaseIterable, Identifiable {
    case todos
    case notifications
    case calendar

    var id: String { rawValue }

    nonisolated var name: String {
        switch self {
        case .todos: "Todos"
        case .notifications: "Notifications"
        case .calendar: "Calendar"
        }
    }

    var symbolName: String {
        switch self {
        case .todos: "checklist"
        case .notifications: "bell"
        case .calendar: "calendar"
        }
    }

    var isAvailable: Bool { self != .calendar }
}
