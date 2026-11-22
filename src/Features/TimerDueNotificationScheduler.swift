import Foundation

@MainActor
final class TimerTodoDueNotificationTask: TodoDueNotificationCancellable {
    private var timer: DispatchSourceTimer?

    init(timer: DispatchSourceTimer) {
        self.timer = timer
    }

    func cancel() {
        timer?.cancel()
        timer = nil
    }
}

@MainActor
enum TimerTodoDueNotificationScheduler {
    static func schedule(
        interval: TimeInterval,
        action: @escaping @MainActor () async -> Void
    ) -> any TodoDueNotificationCancellable {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler {
            Task { @MainActor in await action() }
        }
        timer.resume()
        return TimerTodoDueNotificationTask(timer: timer)
    }
}
