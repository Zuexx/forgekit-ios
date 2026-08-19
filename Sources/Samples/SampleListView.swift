import SwiftUI

struct SampleListView: View {
    @State private var model: SampleListModel

    init(provider: SampleResourceProviding = InMemorySampleResourceProvider()) {
        _model = State(initialValue: SampleListModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Resources")
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let resources):
            List(resources) { resource in
                Text(resource.name)
            }
        case .failed(let reason):
            ContentUnavailableView("Could not load resources", systemImage: "exclamationmark.triangle", description: Text(reason))
        }
    }
}

#Preview {
    SampleListView()
}
