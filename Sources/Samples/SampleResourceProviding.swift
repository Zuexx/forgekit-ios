import Foundation

/// Views depend on this, never on a concrete implementation. That is what lets the model be
/// tested without a network, a simulator, or a running app.
protocol SampleResourceProviding: Sendable {
    func load() async throws -> [SampleResource]
}

struct SampleResourceLoadFailure: Error, Equatable {
    let reason: String
}

/// The implementation the app runs with. Swap it for one that talks to a real backend; the
/// model and the view do not change.
struct InMemorySampleResourceProvider: SampleResourceProviding {
    private let resources: [SampleResource]

    init(resources: [SampleResource] = [
        SampleResource(id: "1", name: "First resource"),
        SampleResource(id: "2", name: "Second resource"),
        SampleResource(id: "3", name: "Third resource"),
    ]) {
        self.resources = resources
    }

    func load() async throws -> [SampleResource] { resources }
}
