import SwiftUI

struct SendNoteToFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendsVM: FriendsViewModel
    let noteId: String
    let noteTitle: String
    @State private var selectedFriend: DBUser? = nil
    @State private var message: String = ""
    @State private var isSending = false
    @State private var error: String?
    @State private var sent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Send \(noteTitle) to a friend")
                    .font(.headline)
                Picker("Friend", selection: $selectedFriend) {
                    ForEach(friendsVM.friends, id: \.id) { friend in
                        Text(friend.username ?? "No username").tag(Optional(friend))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .glassEffect()
                TextField("Add a message (optional)", text: $message)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                if let error = error {
                    Text(error).foregroundColor(.red)
                }
                if sent {
                    Label("Note sent!", systemImage: "paperplane.fill")
                        .foregroundColor(.green)
                }
                Button("Send") {
                    Task { await sendNote() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFriend == nil || isSending)
                Spacer()
            }
            .padding()
            .navigationTitle("Send Note")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel", action: { dismiss() }) } }
        }
    }

    private func sendNote() async {
        guard let friend = selectedFriend else { return }
        isSending = true
        error = nil
        do {
            try await NoteSharingManager.shared.sendNoteShare(to: friend, noteId: noteId, noteTitle: noteTitle, message: message.isEmpty ? nil : message)
            sent = true
        } catch {
            self.error = error.localizedDescription
            sent = false
        }
        isSending = false
    }
}
