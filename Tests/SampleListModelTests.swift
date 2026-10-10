import Testing
@testable import ForgeKit

private struct StubProvider: SampleResourceProviding {
    let result: Result<[SampleResource], SampleResourceLoadFailure>

    func load() async throws -> [SampleResource] {
        switch result {
        case .success(let resources): return resources
        case .failure(let failure): throw failure
        }
    }
}

// Distinct from `SampleResourceLoadFailure` on purpose: it exercises the model's catch-all
// branch, which must never surface an arbitrary error's raw description to the UI.
private struct UnexpectedError: Error {
    let detail: String
}

private struct ThrowingProvider: SampleResourceProviding {
    let error: Error

    func load() async throws -> [SampleResource] {
        throw error
    }
}

@MainActor
struct SampleListModelTests {
    @Test
    func loadPublishesTheResourcesItWasGiven() async {
        let resources = [SampleResource(id: "42", name: "Answer")]
        let model = SampleListModel(provider: StubProvider(result: .success(resources)))

        await model.load()

        // Assert the value, not merely that nothing failed: a state check alone would still
        // pass if load() published an empty list, which is the case worth catching.
        #expect(model.state == .loaded(resources))
    }

    @Test
    func loadSurfacesTheFailureReason() async {
        let model = SampleListModel(provider: StubProvider(result: .failure(.init(reason: "no network"))))

        await model.load()

        #expect(model.state == .failed("no network"))
    }

    @Test
    func loadFallsBackToAFixedGenericMessageForUnexpectedErrors() async {
        let model = SampleListModel(
            provider: ThrowingProvider(error: UnexpectedError(detail: "https://internal.example/debug?token=secret"))
        )

        await model.load()

        // The failure reason must be the fixed generic message, never the raw error
        // description — which would leak `UnexpectedError`'s internal detail into the UI.
        #expect(model.state == .failed(SampleListModel.genericFailureMessage))
    }
}
