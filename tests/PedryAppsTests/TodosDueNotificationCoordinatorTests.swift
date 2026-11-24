import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosDueNotificationCoordinatorTests {
    @Test func fiveMinuteIntervalWaitsForBoundaryAndReviewsEndedWindow() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("In window", at: try fixtureDate(2030, 1, 2, at: 10, minute: 21, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.scheduledDelays == [180, 300])
        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
    }

    @Test func tenMinuteIntervalWaitsUntilTenThirtyAtOneTwentyTwo() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 1, minute: 22, calendar: utcCalendar())
        let env = try makeEnvironment(intervalSeconds: 600, now: now)
        env.addTodo("In window", at: try fixtureDate(2030, 1, 2, at: 1, minute: 21, calendar: env.calendar))
        env.addTodo("Before catch-up", at: try fixtureDate(2030, 1, 2, at: 1, minute: 9, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.scheduledDelays == [480, 600])
        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
    }

    @Test func nonDivisorIntervalFollowsMidnightAnchorAcrossHours() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 0, minute: 50, calendar: utcCalendar())
        let env = try makeEnvironment(intervalSeconds: 1500, now: now)
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.scheduledDelays == [1500, 1500])
    }

    @Test func windowStartIsExclusiveAndBoundaryIsInclusive() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Before catch-up", at: try fixtureDate(2030, 1, 2, at: 9, minute: 54, calendar: env.calendar))
        env.addTodo("On boundary", at: try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar))
        env.addTodo("After boundary", at: try fixtureDate(2030, 1, 2, at: 10, minute: 6, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
    }

    @Test func changingIntervalReschedulesFromCurrentTime() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        await env.coordinator.start()
        #expect(env.scheduledDelays == [180])

        env.settingsStore.setDueCheckIntervalSeconds(600)

        #expect(env.scheduledDelays == [180, 480])
    }

    @Test func launchReviewsOnlyLastCompletedWindow() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Missed", at: try fixtureDate(2030, 1, 2, at: 10, minute: 18, calendar: env.calendar))
        env.addTodo("Partial", at: try fixtureDate(2030, 1, 2, at: 10, minute: 21, calendar: env.calendar))

        await env.coordinator.start()

        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
    }

    @Test func missedWindowIsReviewedAsCatchUp() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let reviewed = try fixtureDate(2030, 1, 2, at: 10, minute: 15, calendar: utcCalendar())
        let env = try makeEnvironment(now: now, stateStore: FakeDueCheckStateStore(lastReviewedBoundary: reviewed))
        env.addTodo("Missed", at: try fixtureDate(2030, 1, 2, at: 10, minute: 18, calendar: env.calendar))

        await env.coordinator.start()

        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
    }

    @Test func intervalChangeNeitherOverlapsNorSkipsReviewedDates() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let reviewed = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(intervalSeconds: 600, now: now, stateStore: FakeDueCheckStateStore(lastReviewedBoundary: reviewed))
        env.addTodo("Reviewed range", at: try fixtureDate(2030, 1, 2, at: 10, minute: 10, calendar: env.calendar))
        env.addTodo("Unreviewed range", at: try fixtureDate(2030, 1, 2, at: 10, minute: 21, calendar: env.calendar))

        await env.coordinator.start()
        await env.scheduler.fire()

        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work", "1 todo is ready to work"])
    }

    @Test func alreadyReviewedWindowIsNotReplayedAfterRestart() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 22, calendar: utcCalendar())
        let reviewed = try fixtureDate(2030, 1, 2, at: 10, minute: 20, calendar: utcCalendar())
        let stateStore = FakeDueCheckStateStore(lastReviewedBoundary: reviewed)
        let env = try makeEnvironment(now: now, stateStore: stateStore)
        env.addTodo("Already sent", at: try fixtureDate(2030, 1, 2, at: 10, minute: 18, calendar: env.calendar))

        await env.coordinator.start()

        #expect(env.center.requests.isEmpty)
    }

    @Test func launchExactlyOnBoundaryReviewsThatBoundaryWindow() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 25, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("On boundary", at: try fixtureDate(2030, 1, 2, at: 10, minute: 23, calendar: env.calendar))

        await env.coordinator.start()

        #expect(env.center.requests.map(\.body) == ["1 todo is ready to work"])
        #expect(env.scheduledDelays == [300])
    }

    @Test func reviewedBoundaryIsRememberedForScheduledChecks() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let stateStore = FakeDueCheckStateStore()
        let env = try makeEnvironment(now: now, stateStore: stateStore)
        await env.coordinator.start()

        await env.scheduler.fire()

        let expected = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        #expect(stateStore.lastReviewedBoundary == expected)
    }

    @Test func dueTodoWithinWindowSendsNotification() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        #expect(env.center.requests == [request(count: 1, endingAt: boundary)])
    }

    @Test func emptyWindowSendsNoNotification() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.requests.isEmpty)
        #expect(env.center.addAttempts == 0)
        #expect(env.poster.posts.isEmpty)
    }

    @Test func dueWindowPostsOneInformationNotificationAlongsideSystemAlert() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        let expectedPost = FakeNotificationPoster.Post(
            source: .todos,
            type: .information,
            title: "Time to work",
            body: "1 todo is ready to work"
        )
        #expect(env.poster.posts == [expectedPost])
        #expect(env.center.requests == [request(count: 1, endingAt: boundary)])
    }

    @Test(arguments: [
        SystemAlertAuthorizationStatus.authorized,
        .denied,
        .unavailable,
    ])
    func todoDueAlertRespectsAuthorizationWithoutChangingInbox(
        status: SystemAlertAuthorizationStatus
    ) async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.center.authorization = status
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        let expected = FakeNotificationPoster.Post(
            source: .todos,
            type: .information,
            title: "Time to work",
            body: "1 todo is ready to work"
        )
        #expect(env.poster.posts == [expected])
        #expect(env.center.requests == (status == .authorized ? [request(count: 1, endingAt: boundary)] : []))
        #expect(env.center.authorizationRequests == 0)
        #expect(env.center.addAttempts == (status == .authorized ? 1 : 0))
    }

    @Test func multipleTodosInSameWindowProduceOneCountNotification() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("A", at: try fixtureDate(2030, 1, 2, at: 10, minute: 2, calendar: env.calendar))
        env.addTodo("B", at: try fixtureDate(2030, 1, 2, at: 10, minute: 4, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.requests.count == 1)
        #expect(env.center.requests.first?.body == "2 todos are ready to work")
    }

    @Test func todoDoesNotNotifyInLaterWindows() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()
        await env.scheduler.fire()
        await env.scheduler.fire()

        #expect(env.center.requests.count == 1)
    }

    @Test func rescheduledFutureDoOnDateNotifiesInItsNewWindow() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()
        await env.scheduler.fire()

        let todo = try #require(env.todosStore.todos.first)
        let second = try fixtureDate(2030, 1, 2, at: 10, minute: 13, calendar: env.calendar)
        env.todosStore.setDoOnDate(DoOnDate(second), for: todo)
        await env.scheduler.fire()
        await env.scheduler.fire()

        #expect(env.center.requests.count == 2)
        #expect(env.center.requests.last?.body == "1 todo is ready to work")
    }

    @Test func authorizationDeniedSkipsDeliverySilently() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.center.authorization = .denied
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.requests.isEmpty)
        #expect(env.center.authorizationRequests == 0)
    }

    @Test func notDeterminedRequestsAuthorization() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.center.authorization = .notDetermined
        env.center.authorizationAfterRequest = .authorized
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.authorizationRequests == 1)
        #expect(env.center.requests.count == 1)
    }

    @Test func deliveryFailureSkipsSilently() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let env = try makeEnvironment(now: now)
        env.center.addError = TestError.delivery
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        #expect(env.center.addAttempts == 1)
    }

    @Test func dueAlertUsesTheSharedSystemAlertPoster() async throws {
        let now = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        let alertPoster = FakeSystemAlertPosting()
        let env = try makeEnvironment(now: now, alertPoster: alertPoster)
        env.addTodo("Buy milk", at: try fixtureDate(2030, 1, 2, at: 10, minute: 3, calendar: env.calendar))
        await env.coordinator.start()

        await env.scheduler.fire()

        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: env.calendar)
        #expect(alertPoster.posts == [request(count: 1, endingAt: boundary)])
    }

    private func makeEnvironment(
        intervalSeconds: Int = 300,
        now: Date,
        stateStore: any TodosDueCheckStoring = FakeDueCheckStateStore(),
        alertPoster: (any SystemAlertPosting)? = nil
    ) throws -> Environment {
        let directory = try TemporaryDirectory()
        let calendar = utcCalendar()
        let todosStore = TodosStore(documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json"))
        let settingsDocument = JSONDocumentStore<TodosSettings>(directory: directory.url, filename: "todos-settings.json")
        try settingsDocument.save(TodosSettings(dueCheckIntervalSeconds: intervalSeconds))
        let settingsStore = TodosSettingsStore(documentStore: settingsDocument)
        let center = FakeSystemAlertCenter()
        let poster = FakeNotificationPoster()
        let clock = MutableClock(now: now)
        let scheduler = Scheduler()
        let coordinator = TodosDueNotificationCoordinator(
            todosStore: todosStore,
            settingsStore: settingsStore,
            stateStore: stateStore,
            alertPoster: alertPoster ?? SystemAlertPoster(center: center),
            notificationPoster: poster,
            calendar: calendar,
            now: { clock.now },
            schedule: { delay, action in scheduler.schedule(delay: delay, action: action) }
        )
        return Environment(
            directory: directory,
            calendar: calendar,
            todosDirectory: directory.url,
            todosStore: todosStore,
            settingsStore: settingsStore,
            center: center,
            poster: poster,
            clock: clock,
            scheduler: scheduler,
            coordinator: coordinator
        )
    }

    private func request(count: Int, endingAt boundary: Date) -> SystemAlertRequest {
        SystemAlertRequest(
            identifier: "due-check:\(boundary.timeIntervalSinceReferenceDate)",
            title: "Time to work",
            body: count == 1 ? "1 todo is ready to work" : "\(count) todos are ready to work"
        )
    }
}

@MainActor
struct TodosDueCheckStateStoreTests {
    @Test func lastReviewedBoundarySurvivesReload() throws {
        let directory = try TemporaryDirectory()
        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: utcCalendar())
        let store = makeStore(in: directory.url)

        store.markReviewed(boundary)

        #expect(makeStore(in: directory.url).lastReviewedBoundary == boundary)
    }

    @Test func olderBoundaryDoesNotReplaceNewer() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)
        let newer = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: utcCalendar())
        let older = try fixtureDate(2030, 1, 2, at: 10, minute: 0, calendar: utcCalendar())
        store.markReviewed(newer)

        store.markReviewed(older)

        #expect(store.lastReviewedBoundary == newer)
    }

    @Test func failedSaveLeavesBoundaryUnchanged() throws {
        let missingDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TodosDueCheckStateStore(
            documentStore: JSONDocumentStore(directory: missingDirectory, filename: "todos-due-check-state.json")
        )
        let boundary = try fixtureDate(2030, 1, 2, at: 10, minute: 5, calendar: utcCalendar())

        store.markReviewed(boundary)

        #expect(store.lastReviewedBoundary == nil)
    }

    private func makeStore(in directory: URL) -> TodosDueCheckStateStore {
        TodosDueCheckStateStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "todos-due-check-state.json")
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
    let center: FakeSystemAlertCenter
    let poster: FakeNotificationPoster
    let clock: MutableClock
    let scheduler: Scheduler
    let coordinator: TodosDueNotificationCoordinator

    init(
        directory: TemporaryDirectory,
        calendar: Calendar,
        todosDirectory: URL,
        todosStore: TodosStore,
        settingsStore: TodosSettingsStore,
        center: FakeSystemAlertCenter,
        poster: FakeNotificationPoster,
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
        self.poster = poster
        self.clock = clock
        self.scheduler = scheduler
        self.coordinator = coordinator
    }

    var scheduledDelays: [TimeInterval] { scheduler.delays }

    func addTodo(_ title: String, at date: Date) {
        if todosStore.categories.isEmpty {
            todosStore.addCategory("Todos")
        }
        guard let category = todosStore.categories.first else { return }
        todosStore.addTodo(title, in: category, doOnDate: DoOnDate(date))
    }
}

@MainActor
private final class FakeNotificationPoster: NotificationPosting {
    struct Post: Equatable {
        let source: MiniApp
        let type: NotificationType
        let title: String
        let body: String
    }

    var posts: [Post] = []

    func post(source: MiniApp, type: NotificationType, title: String, body: String) {
        posts.append(Post(source: source, type: type, title: title, body: body))
    }
}

@MainActor
private final class FakeDueCheckStateStore: TodosDueCheckStoring {
    var lastReviewedBoundary: Date?

    init(lastReviewedBoundary: Date? = nil) {
        self.lastReviewedBoundary = lastReviewedBoundary
    }

    func markReviewed(_ boundary: Date) {
        lastReviewedBoundary = boundary
    }
}

@MainActor
private final class MutableClock {
    var now: Date
    init(now: Date) { self.now = now }
}

@MainActor
private final class Scheduler {
    var delays: [TimeInterval] = []
    private var action: (@MainActor () async -> Void)?

    func schedule(delay: TimeInterval, action: @escaping @MainActor () async -> Void) -> any TodoDueNotificationCancellable {
        delays.append(delay)
        self.action = action
        return AnyCancellableTask()
    }

    func fire() async {
        await action?()
    }
}

@MainActor
private final class AnyCancellableTask: TodoDueNotificationCancellable {
    func cancel() {}
}

private enum TestError: Error { case delivery }
