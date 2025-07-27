import SwiftUI
import FirebaseAuth

struct UserWantsToReviseView: View {
    @StateObject private var viewModel = NotesViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.dueNotes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.category)
                            .font(.headline)
                        Text(note.text)
                        Text(note.importance)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .padding(.vertical, 4)
                    .animation(.smooth, value: viewModel.dueNotes.count)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(note: note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .animation(.smooth, value: viewModel.dueNotes.count)
            .navigationTitle("Your Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .background(.ultraThinMaterial)
            .onAppear {
                Task { await viewModel.loadNotes() }
            }
        }
    }
}

#Preview {
    UserWantsToReviseView()
}
