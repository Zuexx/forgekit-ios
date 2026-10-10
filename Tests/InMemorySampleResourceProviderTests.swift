import Testing
@testable import ForgeKit

// InMemorySampleResourceProvider is the provider the app actually runs with. Until now it was
// only covered indirectly, through SampleListModelTests exercising StubProvider — this asserts
// directly on its load() output, the code path the app really takes.
struct InMemorySampleResourceProviderTests {
    @Test
    func loadReturnsTheDefaultSampleResources() async throws {
        let provider = InMemorySampleResourceProvider()

        let resources = try await provider.load()

        #expect(resources == [
            SampleResource(id: "1", name: "First resource"),
            SampleResource(id: "2", name: "Second resource"),
            SampleResource(id: "3", name: "Third resource"),
        ])
    }

    @Test
    func loadReturnsWhateverResourcesItWasConstructedWith() async throws {
        let resources = [SampleResource(id: "custom", name: "Custom resource")]
        let provider = InMemorySampleResourceProvider(resources: resources)

        let loaded = try await provider.load()

        #expect(loaded == resources)
    }
}
