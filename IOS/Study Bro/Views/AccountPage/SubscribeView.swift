import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import StripePaymentSheet

struct SubscribeView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @StateObject private var userViewModel = userManagerViewModel()

    @State private var showAlert = false
    @State private var showCancelConfirm = false

    var body: some View {
        NavigationStack {
            if let user = userViewModel.user {
                
                VStack(spacing: 20) {
                    
                    if user.isPremium == true {
                        Text("🌟 You are a Premium user!")
                        Button("Manage Subscription") { viewModel.showManage = true }
                        if let subId = user.stripeSubscriptionId {
                            Button("Cancel Subscription") { showCancelConfirm = true }
                                .confirmationDialog("Cancel subscription?", isPresented: $showCancelConfirm) {
                                    Button("Confirm Cancel", role: .destructive) { viewModel.cancel(subscriptionId: subId) }
                                    Button("Keep Subscription", role: .cancel) {}
                                }
                        }
                    } else {
                        Text("Upgrade to Premium to unlock all features.")
                        Button("Subscribe Now") { viewModel.subscribe(monthly: true) }
                    }
                    if let msg = viewModel.statusMessage {
                        Text(msg).foregroundColor(.blue)
                    }
                }
                .sheet(isPresented: $viewModel.isPaymentSheetPresented) {
                    if let sheet = viewModel.paymentSheet {
                        PaymentSheetHost(paymentSheet: sheet) { result in
                            viewModel.onPaymentCompletion(result: result)
                        }
                    }
                }
                .alert("Subscription", isPresented: $showAlert, presenting: viewModel.statusMessage) { _ in } message: { Text($0) }
                .onChange(of: viewModel.statusMessage) { _, newMessage in showAlert = newMessage != nil }
            }
            
        }
        .onAppear() {
            Task {
                try await userViewModel.loadCurrentUser()
            }
        }
    }
}

struct PaymentSheetHost: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let completion: (PaymentSheetResult) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true
        paymentSheet.present(from: uiViewController) { result in completion(result) }
    }

    final class Coordinator {
        var didPresent = false
        let parent: PaymentSheetHost
        init(_ parent: PaymentSheetHost) { self.parent = parent }
    }
}
