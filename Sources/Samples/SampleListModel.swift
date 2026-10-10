import Foundation
import Observation

@MainActor
@Observable
final class SampleListModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([SampleResource])
        case failed(String)
    }

    // The fallback shown to the user for any error that isn't a `SampleResourceLoadFailure`.
    // Never substitute `String(describing: error)` here: this is template code meant to be
    // copied into a real provider, and a provider talking to a real backend can throw
    // `URLError`, a decode failure, or other internal detail that must not reach the UI.
    static let genericFailureMessage = "Something went wrong. Please try again."

    private(set) var state: State = .idle

    private let provider: SampleResourceProviding

    init(provider: SampleResourceProviding) {
        self.provider = provider
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await provider.load())
        } catch let failure as SampleResourceLoadFailure {
            state = .failed(failure.reason)
        } catch {
            // The real error is logged here, not discarded — it just never becomes the
            // user-facing reason.
            print("SampleListModel.load failed with an unexpected error: \(error)")
            state = .failed(Self.genericFailureMessage)
        }
    }
}
