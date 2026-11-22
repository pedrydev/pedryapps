import Testing
@testable import PedryApps

@MainActor
struct TodosSettingsTests {
    @Test func defaultIntervalIsFiveMinutes() {
        #expect(TodosSettings.default.dueCheckIntervalSeconds == 300)
        #expect(TodosSettings.default.dueCheckIntervalMinutes == 5)
    }

    @Test(arguments: [
        (minutes: 5, seconds: 300),
        (minutes: 30, seconds: 1800),
        (minutes: 60, seconds: 3600),
    ])
    func convertingBoundaryMinutesToSeconds(minutes: Int, seconds: Int) {
        #expect(TodosSettings.seconds(fromMinutes: minutes) == seconds)
    }

    @Test(arguments: [-1, 0, 4, 6, 7, 59, 61])
    func minutesOutsideTheFiveMinuteGridAreRejected(_ minutes: Int) {
        #expect(TodosSettings.seconds(fromMinutes: minutes) == nil)
    }

    @Test(arguments: [
        (seconds: 60, minutes: 5),
        (seconds: 420, minutes: 5),
        (seconds: 480, minutes: 10),
        (seconds: 2580, minutes: 45),
        (seconds: 3720, minutes: 60),
    ])
    func offGridStoredIntervalsSnapToTheNearestStep(seconds: Int, minutes: Int) {
        let settings = TodosSettings(dueCheckIntervalSeconds: seconds)

        #expect(settings.dueCheckIntervalMinutes == minutes)
        #expect(settings.snappedDueCheckIntervalSeconds == minutes * 60)
    }
}
