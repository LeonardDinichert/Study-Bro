import Foundation
import Combine

@MainActor
class NoteSharingViewModel: ObservableObject {
    @Published var incomingRequests: [NoteShareRequest] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private var cancellables = Set<AnyCancellable>()

    /// Loads incoming share requests for the current user
    func loadIncoming() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let userId = try await UserManager.shared.loadCurrentUserId()
            let reqs = try await NoteSharingManager.shared.fetchIncomingRequests(for: userId)
            self.incomingRequests = reqs
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    /// Accepts a share request
    func accept(_ req: NoteShareRequest) async {
        do {
            try await NoteSharingManager.shared.acceptNoteShare(request: req)
            await loadIncoming()
        } catch {
            self.error = error.localizedDescription
        }
    }
    /// Ignores a share request
    func ignore(_ req: NoteShareRequest) async {
        do {
            try await NoteSharingManager.shared.ignoreNoteShare(request: req)
            await loadIncoming()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
