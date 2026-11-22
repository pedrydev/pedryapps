import Testing
@testable import PedryApps

@MainActor
struct TodosSettingsTests {
    @Test func defaultIntervalIsFiveMinutes() {
        #expect(TodosSettings.default.dueCheckIntervalSeconds == 300)
        #expect(TodosSettings.default.dueCheckIntervalMinutes == 5)
    }

    @Test(arguments: [
        (minutes: 1, seconds: 60),
        (minutes: 5, seconds: 300),
        (minutes: 60, seconds: 3600),
    ])
    func convertingBoundaryMinutesToSeconds(minutes: Int, seconds: Int) {
        #expect(TodosSettings.seconds(fromMinutes: minutes) == seconds)
    }

    @Test(arguments: [-1, 0, 61])
    func minutesOutsideBoundsAreRejected(_ minutes: Int) {
        #expect(TodosSettings.seconds(fromMinutes: minutes) == nil)
    }
}
