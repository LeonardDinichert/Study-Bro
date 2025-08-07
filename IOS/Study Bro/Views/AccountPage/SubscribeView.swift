import SwiftUI

struct SubscribeView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    
    let userEmail: String

    var body: some View {
        VStack(spacing: 20) {
            Button("Subscribe") {
                viewModel.subscribe(email: userEmail)
            }
            .buttonStyle(.borderedProminent)

            if let message = viewModel.paymentStatus {
                Text(message)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Subscribe")
    }
}

#Preview {
    SubscribeView(userEmail: "jim@example.com")
}
