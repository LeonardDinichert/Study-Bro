import Foundation
import Adyen

@MainActor
final class SubscriptionViewModel: NSObject, ObservableObject, AdyenSessionDelegate {
    @Published var paymentStatus: String?

    func subscribe(paymentAmount: Int = 1000) {
        AdyenPaymentManager.shared.startSubscription(paymentAmount: paymentAmount, delegate: self)
    }

    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
        switch result.resultCode {
        case .authorised:
            paymentStatus = "Subscription purchase successful! 🎉"
        case .cancelled:
            paymentStatus = "Payment was cancelled."
        case .refused:
            paymentStatus = "Payment was refused. Please try another method."
        case .error:
            paymentStatus = "Payment error: \(result.errorMessage ?? "unknown error")."
        case .pending, .received:
            paymentStatus = "Payment is pending confirmation."
        }
        component.dismiss(animated: true)
    }

    func didFail(with error: Error, from component: Component, during session: AdyenSession) {
        paymentStatus = "Payment error: \(error.localizedDescription)"
        component.dismiss(animated: true)
    }
}
