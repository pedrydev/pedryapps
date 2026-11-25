import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosProbedComponentAdapterTests {
    @Test func healthyWhenTodosHasNoError() throws {
        let checkedAt = Date(timeIntervalSince1970: 1_704_067_200)
        let directory = try TemporaryDirectory()
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json")
        )

        let probedComponent = TodosProbedComponentAdapter(
            store: store,
            checkedAt: checkedAt
        ).probedComponent

        #expect(probedComponent.id == "todos")
        #expect(probedComponent.name == "Todos")
        #expect(probedComponent.healthState == .healthy)
        #expect(
            probedComponent.probeResults == [
                ProbeResult(
                    kind: .startup,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                ),
                ProbeResult(
                    kind: .liveness,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                ),
                ProbeResult(
                    kind: .readiness,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                ),
            ]
        )
    }

    @Test func storeErrorFailsProbesAndHealthState() throws {
        let checkedAt = Date(timeIntervalSince1970: 1_704_067_200)
        let directory = try TemporaryDirectory()
        let documentURL = directory.url.appendingPathComponent("board.json")
        try Data("not json".utf8).write(to: documentURL)
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json")
        )
        let errorText = try #require(store.errorMessage)

        let probedComponent = TodosProbedComponentAdapter(
            store: store,
            checkedAt: checkedAt
        ).probedComponent

        #expect(probedComponent.healthState == .unhealthy)
        #expect(
            probedComponent.probeResults == [
                ProbeResult(
                    kind: .startup,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                ),
                ProbeResult(
                    kind: .liveness,
                    outcome: .failure,
                    checkedAt: checkedAt,
                    errorText: errorText
                ),
                ProbeResult(
                    kind: .readiness,
                    outcome: .failure,
                    checkedAt: checkedAt,
                    errorText: errorText
                ),
            ]
        )
    }
}
