import Foundation
import Testing

@testable import PedryApps

struct ProbeEvaluatorTests {
    private let checkedAt = Date(timeIntervalSince1970: 1_704_067_200)

    @Test func mapsSatisfiedCheckToSuccessResult() {
        let result = ProbeEvaluator.result(
            kind: .startup,
            isConditionMet: true,
            checkedAt: checkedAt,
            errorText: "Ignored"
        )

        #expect(
            result
                == ProbeResult(
                    kind: .startup,
                    outcome: .success,
                    checkedAt: checkedAt,
                    errorText: nil
                )
        )
    }

    @Test func mapsUnsatisfiedCheckToFailureResultWithErrorText() {
        let result = ProbeEvaluator.result(
            kind: .liveness,
            isConditionMet: false,
            checkedAt: checkedAt,
            errorText: "Store error"
        )

        #expect(result.outcome == .failure)
        #expect(result.errorText == "Store error")
    }

    @Test func mapsUnknownOutcomeToUnknownResult() {
        let result = ProbeEvaluator.result(
            kind: .readiness,
            outcome: .unknown,
            checkedAt: checkedAt,
            errorText: "Not checked"
        )

        #expect(
            result
                == ProbeResult(
                    kind: .readiness,
                    outcome: .unknown,
                    checkedAt: checkedAt,
                    errorText: "Not checked"
                )
        )
    }

    @Test func healthStateIsHealthyWhenAllProbesSucceed() {
        let results = ProbeKind.allCases.map { kind in
            ProbeResult(kind: kind, outcome: .success, checkedAt: checkedAt, errorText: nil)
        }

        #expect(ProbeEvaluator.healthState(from: results) == .healthy)
    }

    @Test func healthStateIsUnhealthyWhenLivenessFails() {
        let results = [
            result(kind: .startup, outcome: .success),
            result(kind: .liveness, outcome: .failure),
            result(kind: .readiness, outcome: .success),
        ]

        #expect(ProbeEvaluator.healthState(from: results) == .unhealthy)
    }

    @Test func healthStateIsDegradedWhenReadinessFails() {
        let results = [
            result(kind: .startup, outcome: .success),
            result(kind: .liveness, outcome: .success),
            result(kind: .readiness, outcome: .failure),
        ]

        #expect(ProbeEvaluator.healthState(from: results) == .degraded)
    }

    @Test func healthStateIsUnknownWhenAnyProbeIsUnknown() {
        let results = [
            result(kind: .startup, outcome: .success),
            result(kind: .liveness, outcome: .success),
            result(kind: .readiness, outcome: .unknown),
        ]

        #expect(ProbeEvaluator.healthState(from: results) == .unknown)
    }

    @Test func healthStateIsUnknownWhenLivenessIsUnknownAndReadinessFails() {
        let results = [
            result(kind: .startup, outcome: .success),
            result(kind: .liveness, outcome: .unknown),
            result(kind: .readiness, outcome: .failure),
        ]

        #expect(ProbeEvaluator.healthState(from: results) == .unknown)
    }

    @Test func healthStateIsStartingWhenProbeResultsAreIncomplete() {
        let results = [result(kind: .startup, outcome: .success)]

        #expect(ProbeEvaluator.healthState(from: results) == .starting)
    }

    @Test func healthStateIsStartingWhenThereAreNoProbeResults() {
        #expect(ProbeEvaluator.healthState(from: []) == .starting)
    }

    private func result(kind: ProbeKind, outcome: ProbeOutcome) -> ProbeResult {
        ProbeResult(kind: kind, outcome: outcome, checkedAt: checkedAt, errorText: nil)
    }
}
