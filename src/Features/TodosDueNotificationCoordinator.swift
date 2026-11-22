import Foundation

@MainActor
protocol TodoDueNotificationCancellable: AnyObject {
    func cancel()
}

@MainActor
final class TodosDueNotificationCoordinator {
    private let todosStore: TodosStore
    private let settingsStore: TodosSettingsStore
    private let stateStore: any TodosDueCheckStoring
    private let notificationCenter: any TodoDueNotificationCenter
    private let calendar: Calendar
    private let now: @MainActor () -> Date
    private let schedule: @MainActor (TimeInterval, @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable

    private var task: (any TodoDueNotificationCancellable)?

    init(
        todosStore: TodosStore,
        settingsStore: TodosSettingsStore,
        stateStore: any TodosDueCheckStoring,
        notificationCenter: any TodoDueNotificationCenter,
        calendar: Calendar = .current,
        now: @escaping @MainActor () -> Date = { Date() },
        schedule: @escaping @MainActor (TimeInterval, @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable
    ) {
        self.todosStore = todosStore
        self.settingsStore = settingsStore
        self.stateStore = stateStore
        self.notificationCenter = notificationCenter
        self.calendar = calendar
        self.now = now
        self.schedule = schedule
        settingsStore.onDueCheckIntervalChange = { [weak self] in self?.reschedule() }
    }

    func start() async {
        task?.cancel()
        let current = now()
        let interval = TimeInterval(settingsStore.settings.snappedDueCheckIntervalSeconds)
        let lastBoundary = boundary(atOrBefore: current, interval: interval)
        if stateStore.lastReviewedBoundary.map({ $0 < lastBoundary }) ?? true {
            await review(endingAt: lastBoundary, interval: interval)
        }
        scheduleNext(from: current)
    }

    private func reschedule() {
        task?.cancel()
        scheduleNext(from: now())
    }

    private func scheduleNext(from date: Date) {
        let interval = TimeInterval(settingsStore.settings.snappedDueCheckIntervalSeconds)
        let boundary = nextBoundary(after: date, interval: interval)
        task = schedule(boundary.timeIntervalSince(date)) { [weak self] in
            guard let self else { return }
            await self.review(endingAt: boundary, interval: interval)
            self.scheduleNext(from: boundary)
        }
    }

    private func nextBoundary(after date: Date, interval: TimeInterval) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let elapsed = date.timeIntervalSince(dayStart)
        return dayStart.addingTimeInterval((floor(elapsed / interval) + 1) * interval)
    }

    private func boundary(atOrBefore date: Date, interval: TimeInterval) -> Date {
        nextBoundary(after: date.addingTimeInterval(-interval), interval: interval)
    }

    private func review(endingAt boundary: Date, interval: TimeInterval) async {
        guard boundary > (stateStore.lastReviewedBoundary ?? .distantPast) else { return }
        let window = DueCheckWindow.ending(
            at: boundary,
            interval: interval,
            lastReviewedBoundary: stateStore.lastReviewedBoundary
        )
        stateStore.markReviewed(boundary)
        let due = todosStore.todos.filter { window.contains($0.doOnDate.date) }
        guard !due.isEmpty else { return }
        let status = await notificationCenter.authorizationStatus()
        let resolved: TodoNotificationAuthorizationStatus
        if status == .notDetermined {
            resolved = await notificationCenter.requestAuthorization()
        } else {
            resolved = status
        }
        guard resolved == .authorized else { return }
        let body = due.count == 1 ? "1 todo is ready to work" : "\(due.count) todos are ready to work"
        let request = TodoDueNotificationRequest(
            identifier: "due-check:\(boundary.timeIntervalSinceReferenceDate)",
            title: "Time to work",
            body: body
        )
        try? await notificationCenter.add(request)
    }
}
