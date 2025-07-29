import SwiftUI

struct TrophiesView: View {
    @StateObject private var viewModel = TrophiesViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.trophies.isEmpty {
                    Text("No trophies yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.trophies, id: \._self) { trophy in
                        Text(trophy)
                    }
                }
            }
            .navigationTitle("Trophies")
        }
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    TrophiesView()
}
