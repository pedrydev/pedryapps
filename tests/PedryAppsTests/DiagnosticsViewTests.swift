import SwiftUI
import Testing
@testable import PedryApps

@Suite(.serialized)
@MainActor
struct DiagnosticsViewTests {
    @Test(
        "Diagnostics panel renders the injected probed component and health state",
        arguments: [
            (HealthState.starting, "Starting"),
            (.healthy, "Healthy"),
            (.degraded, "Degraded"),
            (.unhealthy, "Unhealthy"),
            (.unknown, "Unknown"),
        ]
    )
    func panelRendersInjectedState(state: HealthState, expectedLabel: String) {
        let probedComponent = ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: state,
            probeResults: []
        )

        let actual = imageData(
            renderedImage(
                of: DiagnosticsView(probedComponent: probedComponent, isExpanded: .constant(false))
                    .frame(width: 320, height: 100)
            )
        )
        let expected = imageData(
            renderedImage(
                of: referenceCollapsedView(label: expectedLabel)
                    .frame(width: 320, height: 100)
            )
        )
        let different = imageData(
            renderedImage(
                of: referenceCollapsedView(label: "Other")
                    .frame(width: 320, height: 100)
            )
        )

        #expect(actual == expected)
        #expect(actual != different)
    }

    @Test func expandedRowShowsProbeResults() {
        let checkedAt = Date(timeIntervalSince1970: 1_704_067_200)
        let probedComponent = ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: .degraded,
            probeResults: [
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
                    errorText: "Store error"
                ),
                ProbeResult(
                    kind: .readiness,
                    outcome: .unknown,
                    checkedAt: nil,
                    errorText: "Board not loaded"
                ),
            ]
        )
        let timeText = checkedAt.formatted(date: .abbreviated, time: .shortened)

        let actual = imageData(
            renderedImage(
                of: DiagnosticsView(probedComponent: probedComponent, isExpanded: .constant(true))
                    .frame(width: 400, height: 400)
            )
        )
        let expected = imageData(
            renderedImage(
                of: referenceExpandedView(timeText: timeText)
                    .frame(width: 400, height: 400)
            )
        )
        let differentTime = imageData(
            renderedImage(
                of: referenceExpandedView(timeText: "Wrong")
                    .frame(width: 400, height: 400)
            )
        )

        #expect(actual == expected)
        #expect(actual != differentTime)
    }

    private func referenceCollapsedView(label: String) -> some View {
        Form {
            DisclosureGroup(isExpanded: .constant(false)) {
                EmptyView()
            } label: {
                LabeledContent {
                    Text(verbatim: label)
                } label: {
                    Text(verbatim: "Todos")
                }
            }
        }
    }

    private func referenceExpandedView(timeText: String) -> some View {
        Form {
            DisclosureGroup(isExpanded: .constant(true)) {
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent {
                        Text(verbatim: "Success")
                    } label: {
                        Text(verbatim: "Startup")
                    }
                    LabeledContent("Last check") {
                        Text(verbatim: timeText)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent {
                        Text(verbatim: "Failure")
                    } label: {
                        Text(verbatim: "Liveness")
                    }
                    LabeledContent("Last check") {
                        Text(verbatim: timeText)
                    }
                    Text(verbatim: "Store error")
                }
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent {
                        Text(verbatim: "Unknown")
                    } label: {
                        Text(verbatim: "Readiness")
                    }
                    LabeledContent("Last check") {
                        Text(verbatim: "Not checked")
                    }
                    Text(verbatim: "Board not loaded")
                }
            } label: {
                LabeledContent {
                    Text(verbatim: "Degraded")
                } label: {
                    Text(verbatim: "Todos")
                }
            }
        }
    }

    private func renderedImage(of view: some View) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.cgImage
    }

    private func imageData(_ image: CGImage?) -> [UInt8]? {
        guard let image, let data = image.dataProvider?.data else { return nil }
        return Array(
            UnsafeBufferPointer(
                start: CFDataGetBytePtr(data),
                count: CFDataGetLength(data)
            )
        )
    }
}
