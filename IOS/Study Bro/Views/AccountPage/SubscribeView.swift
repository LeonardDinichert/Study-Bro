import SwiftUI

struct SubscribeView: View {
    @StateObject private var viewModel = SubscriptionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Button("Subscribe") {
                viewModel.subscribe()
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
    SubscribeView()
}
