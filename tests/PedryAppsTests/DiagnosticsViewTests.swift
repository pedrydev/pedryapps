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
        let probedComponent = ProbedComponent(id: "todos", name: "Todos", healthState: state)

        let actual = imageData(
            renderedImage(
                of: DiagnosticsView(probedComponent: probedComponent)
                    .frame(width: 320, height: 100)
            )
        )
        let expected = imageData(
            renderedImage(
                of: referenceView(label: expectedLabel)
                    .frame(width: 320, height: 100)
            )
        )
        let different = imageData(
            renderedImage(
                of: referenceView(label: "Other")
                    .frame(width: 320, height: 100)
            )
        )

        #expect(actual == expected)
        #expect(actual != different)
    }

    private func referenceView(label: String) -> some View {
        Form {
            LabeledContent {
                Text(verbatim: label)
            } label: {
                Text(verbatim: "Todos")
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
