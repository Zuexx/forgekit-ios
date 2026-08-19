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
            state = .failed(String(describing: error))
        }
    }
}
