enum MiniApp: String, CaseIterable, Identifiable {
    case todos
    case notifications
    case calendar

    var id: String { rawValue }

    var name: String {
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

    var isAvailable: Bool { self == .todos }
}
