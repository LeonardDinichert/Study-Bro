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
                    .swipeActions {
//                        Button {
//                            Task { await viewModel.markReviewed(note: note) }
//                        } label: {
//                            Label("Done", systemImage: "checkmark")
//                        }
                        Button(role: .destructive) {
                            Task { await viewModel.delete(note: note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Your Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                Task { await viewModel.loadNotes() }
            }
        }
    }
}

#Preview {
    UserWantsToReviseView()
}
