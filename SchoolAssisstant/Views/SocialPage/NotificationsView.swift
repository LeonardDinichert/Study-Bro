import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.incomingRequests, id: \.id) { user in
                    HStack {
                        Text(user.username ?? "no username")
                        Spacer()
                        Button("Accept") {
                            Task {
                                try await viewModel.acceptFriendRequest(from: user)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Decline") {
                            Task {
                                try await viewModel.declineFriendRequest(from: user)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    .refreshable {
                        Task {try await viewModel.loadPendingRequests() }}
                }
            }
            
        }
        .navigationTitle("Notifications")
        .onAppear {
            Task {
                try await viewModel.loadPendingRequests()
               
            }
        }
        
    }
}

//#Preview {
//    NotificationsView()
//}
