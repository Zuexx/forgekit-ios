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
}
