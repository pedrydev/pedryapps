import Foundation

@MainActor
protocol TodoDueNotificationCancellable: AnyObject {
    func cancel()
}

@MainActor
final class TodosDueNotificationCoordinator {
    private let todosStore: TodosStore
    private let settingsStore: TodosSettingsStore
    private let notificationCenter: any TodoDueNotificationCenter
    private let now: @MainActor () -> Date
    private let schedule: @MainActor (TimeInterval, @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable

    private var lastCheck: Date?
    private var task: (any TodoDueNotificationCancellable)?

    init(
        todosStore: TodosStore,
        settingsStore: TodosSettingsStore,
        notificationCenter: any TodoDueNotificationCenter,
        now: @escaping @MainActor () -> Date = { Date() },
        schedule: @escaping @MainActor (TimeInterval, @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable
    ) {
        self.todosStore = todosStore
        self.settingsStore = settingsStore
        self.notificationCenter = notificationCenter
        self.now = now
        self.schedule = schedule
    }

    func start() {
        task?.cancel()
        task = schedule(TimeInterval(settingsStore.settings.dueCheckIntervalSeconds)) { [weak self] in
            await self?.checkNow()
        }
    }

    func checkNow() async {
        let current = now()
        let interval = TimeInterval(settingsStore.settings.dueCheckIntervalSeconds)
        let windowStart = lastCheck ?? current.addingTimeInterval(-interval)
        lastCheck = current
        let due = todosStore.todos.filter { $0.doOnDate.date > windowStart && $0.doOnDate.date <= current }
        guard !due.isEmpty else { return }
        let status = await notificationCenter.authorizationStatus()
        let resolved: TodoNotificationAuthorizationStatus
        if status == .notDetermined {
            resolved = await notificationCenter.requestAuthorization()
        } else {
            resolved = status
        }
        guard resolved == .authorized else { return }
        for todo in due {
            let request = TodoDueNotificationRequest(
                identifier: todo.id.uuidString + ":\(todo.doOnDate.date.timeIntervalSinceReferenceDate)",
                title: "Time to work",
                body: todo.title
            )
            try? await notificationCenter.add(request)
        }
    }
}
