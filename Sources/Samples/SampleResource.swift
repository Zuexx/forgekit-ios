import Foundation

/// The one domain type this starter ships. It exists to prove the chain from a service through
/// a model to a view is wired and tested — replace it with a real domain rather than building
/// around it.
struct SampleResource: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
}
