import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosDueNotificationCoordinatorTests {
    @Test func dueTodoWithinWindowSendsNotification() async throws {
        let env = try makeEnvironment()
        let due = try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar)
        env.addTodo("Buy milk", at: due)

        await env.coordinator.checkNow()

        #expect(env.center.requests == [request(for: env.todosStore.todos[0], title: "Buy milk")])
    }

    @Test func firstCheckUsesFiveMinuteLookback() async throws {
        let env = try makeEnvironment()
        env.addTodo("Recent", at: try fixtureDate(2030, 1, 2, at: 9, minute: 56, calendar: env.calendar))
        env.addTodo("Old", at: try fixtureDate(2030, 1, 2, at: 9, minute: 54, calendar: env.calendar))

        #expect(env.todosStore.todos.count == 2, "err: \(env.todosStore.errorMessage ?? "nil")")
        await env.coordinator.checkNow()

        #expect(env.center.requests.map(\.body) == ["Recent"])
        #expect(env.clock.now == (try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: env.calendar)))
    }

    @Test func todoExactlyOnWindowBoundaryIsNotNotified() async throws {
        let env = try makeEnvironment()
        env.addTodo("Boundary", at: try fixtureDate(2030, 1, 2, at: 9, minute: 55, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.requests.isEmpty)
    }

    @Test func multipleTodosQualifyingInSameCheckProduceOneNotificationEach() async throws {
        let env = try makeEnvironment()
        env.addTodo("A", at: try fixtureDate(2030, 1, 2, at: 9, minute: 56, calendar: env.calendar))
        env.addTodo("B", at: try fixtureDate(2030, 1, 2, at: 9, minute: 59, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.requests.map(\.body) == ["A", "B"])
    }

    @Test func unchangedPassedTodoDoesNotNotifyAgain() async throws {
        let env = try makeEnvironment()
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar))

        await env.coordinator.checkNow()
        env.clock.now = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        await env.coordinator.checkNow()

        #expect(env.center.requests.count == 1)
    }

    @Test func rescheduledFutureDoOnDateNotifiesOnNewCrossing() async throws {
        let env = try makeEnvironment()
        let first = try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar)
        env.addTodo("Buy milk", at: first)
        await env.coordinator.checkNow()

        let todo = try #require(env.todosStore.todos.first)
        let second = try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar)
        env.todosStore.setDoOnDate(DoOnDate(second), for: todo)
        env.clock.now = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        await env.coordinator.checkNow()

        #expect(env.center.requests.count == 2)
        #expect(env.center.requests.last?.body == "Buy milk")
    }

    @Test func authorizationDeniedSkipsDeliverySilently() async throws {
        let env = try makeEnvironment()
        env.center.authorization = .denied
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.requests.isEmpty)
        #expect(env.center.authorizationRequests == 0)
    }

    @Test func notDeterminedRequestsAuthorization() async throws {
        let env = try makeEnvironment()
        env.center.authorization = .notDetermined
        env.center.authorizationAfterRequest = .authorized
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.authorizationRequests == 1)
        #expect(env.center.requests.count == 1)
    }

    @Test func deliveryFailureSkipsSilently() async throws {
        let env = try makeEnvironment()
        env.center.addError = TestError.delivery
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 9, minute: 58, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.addAttempts == 1)
    }

    @Test func usesConfiguredIntervalForLookbackAndScheduling() async throws {
        let env = try makeEnvironment(intervalSeconds: 60)
        env.addTodo("Recent", at: try fixtureDate(2030, 1, 2, at: 9, minute: 59, second: 30, calendar: env.calendar))
        env.addTodo("Old", at: try fixtureDate(2030, 1, 2, at: 9, minute: 58, second: 30, calendar: env.calendar))

        await env.coordinator.checkNow()

        #expect(env.center.requests.map(\.body) == ["Recent"])
        #expect(env.scheduledIntervals == [60])
    }

    private func makeEnvironment(intervalSeconds: Int = 300) throws -> Environment {
        let directory = try TemporaryDirectory()
        let calendar = utcCalendar()
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: calendar)
        let todosStore = TodosStore(documentStore: JSONDocumentStore(directory: directory.url, filename: "todos.json"))
        let settingsDocument = JSONDocumentStore<TodosSettings>(directory: directory.url, filename: "todos-settings.json")
        try settingsDocument.save(TodosSettings(dueCheckIntervalSeconds: intervalSeconds))
        let settingsStore = TodosSettingsStore(documentStore: settingsDocument)
        let center = FakeTodoNotificationCenter()
        let clock = MutableClock(now: now)
        let scheduler = Scheduler()
        let coordinator = TodosDueNotificationCoordinator(
            todosStore: todosStore,
            settingsStore: settingsStore,
            notificationCenter: center,
            now: { clock.now },
            schedule: { interval, action in scheduler.schedule(interval: interval, action: action) }
        )
        coordinator.start()
        return Environment(
            directory: directory,
            calendar: calendar,
            todosDirectory: directory.url,
            todosStore: todosStore,
            settingsStore: settingsStore,
            center: center,
            clock: clock,
            scheduler: scheduler,
            coordinator: coordinator
        )
    }

    private func request(for todo: Todo, title: String) -> TodoDueNotificationRequest {
        TodoDueNotificationRequest(
            identifier: "\(todo.id.uuidString):\(todo.doOnDate.date.timeIntervalSinceReferenceDate)",
            title: "Time to work",
            body: title
        )
    }
}

@MainActor
private final class Environment {
    let directory: TemporaryDirectory
    let calendar: Calendar
    let todosDirectory: URL
    let todosStore: TodosStore
    let settingsStore: TodosSettingsStore
    let center: FakeTodoNotificationCenter
    let clock: MutableClock
    let scheduler: Scheduler
    let coordinator: TodosDueNotificationCoordinator

    init(
        directory: TemporaryDirectory,
        calendar: Calendar,
        todosDirectory: URL,
        todosStore: TodosStore,
        settingsStore: TodosSettingsStore,
        center: FakeTodoNotificationCenter,
        clock: MutableClock,
        scheduler: Scheduler,
        coordinator: TodosDueNotificationCoordinator
    ) {
        self.directory = directory
        self.calendar = calendar
        self.todosDirectory = todosDirectory
        self.todosStore = todosStore
        self.settingsStore = settingsStore
        self.center = center
        self.clock = clock
        self.scheduler = scheduler
        self.coordinator = coordinator
    }

    var scheduledIntervals: [TimeInterval] { scheduler.intervals }

    func addTodo(_ title: String, at date: Date) {
        let todo = Todo(title: title, doOnDate: DoOnDate(date))
        let documentStore = JSONDocumentStore<TodosDocument>(directory: todosDirectory, filename: "todos.json")
        var document = (try? documentStore.load()) ?? TodosDocument()
        document.todos.append(todo)
        try? documentStore.save(document)
        todosStore.load()
    }

}

@MainActor
private final class FakeTodoNotificationCenter: TodoDueNotificationCenter {
    var authorization: TodoNotificationAuthorizationStatus = .authorized
    var authorizationAfterRequest: TodoNotificationAuthorizationStatus = .authorized
    var authorizationRequests = 0
    var requests: [TodoDueNotificationRequest] = []
    var addAttempts = 0
    var addError: Error?

    func authorizationStatus() async -> TodoNotificationAuthorizationStatus { authorization }

    func requestAuthorization() async -> TodoNotificationAuthorizationStatus {
        authorizationRequests += 1
        authorization = authorizationAfterRequest
        return authorization
    }

    func add(_ request: TodoDueNotificationRequest) async throws {
        addAttempts += 1
        if let addError { throw addError }
        requests.append(request)
    }
}

@MainActor
private final class MutableClock {
    var now: Date
    init(now: Date) { self.now = now }
}

@MainActor
private final class Scheduler {
    var intervals: [TimeInterval] = []

    func schedule(interval: TimeInterval, action: @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable {
        intervals.append(interval)
        return AnyCancellableTask()
    }
}

@MainActor
private final class AnyCancellableTask: TodoDueNotificationCancellable {
    func cancel() {}
}

private enum TestError: Error { case delivery }
