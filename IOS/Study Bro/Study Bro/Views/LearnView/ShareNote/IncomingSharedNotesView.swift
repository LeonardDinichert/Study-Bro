import SwiftUI
import FirebaseAuth

struct IncomingSharedNotesView: View {
    @ObservedObject var viewModel: NoteSharingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var lastAcceptedNoteId: String?
    @Binding var showIncomingShares: Bool
    @Binding var showSetImportanceSheet: Bool

    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }
                if let error = viewModel.error {
                    Text(error).foregroundColor(.red)
                }
                ForEach(viewModel.incomingRequests) { req in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(req.noteTitle)
                                .font(.headline)
                            if let msg = req.message, !msg.isEmpty {
                                Text("\"\(msg)\"")
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                            Text("From: \(req.senderName)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text("Sent: \(req.sentAt.formatted(.dateTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        if req.accepted == nil {
                            HStack {
                                
                                Button(role: .none) {
                                    Task {
                                        await viewModel.accept(req)
                                        showIncomingShares = false
                                        lastAcceptedNoteId = req.noteId
                                        showSetImportanceSheet = true
                                    }
                                } label: {
                                    Text("Accept the Study Note")
                                }
                                
//                                Button(role: .destructive) {
//                                    Task {
//                                        await viewModel.ignore(req)
//                                        showIncomingShares = false
//                                        print("clik r")
//                                        
//                                    }
//                                } label: {
//                                    Text("Ignore it")
//                                    
//                                }
                            }
                        } else if req.accepted == true {
                            Label("Accepted", systemImage: "hand.thumbsup.fill").foregroundColor(.green)
                        } else {
                            Label("Ignored", systemImage: "hand.thumbsdown").foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Shared Notes")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close", action: { dismiss() }) } }
        }
        .onAppear {
            Task { await viewModel.loadIncoming() }
        }
    }
}

