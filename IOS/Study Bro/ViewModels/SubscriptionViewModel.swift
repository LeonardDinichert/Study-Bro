import Foundation
import AdyenSession
import FirebaseCoreExtension
import UIKit
import Adyen

final class SubscriptionViewModel: NSObject, ObservableObject, @MainActor AdyenSessionDelegate {
    
    @Published var paymentStatus: String?

    func subscribe(paymentAmount: Int = 1000) {
        AdyenPaymentManager.shared.startSubscription(paymentAmount: paymentAmount, delegate: self)
    }

    func didComplete(with result: AdyenSessionResult, component: Adyen.Component, session: AdyenSession) {
        switch result.resultCode {
        case .authorised:
            paymentStatus = "Subscription purchase successful! 🎉"
        case .cancelled:
            paymentStatus = "Payment was cancelled."
        case .refused:
            paymentStatus = "Payment was refused. Please try another method."
        case .error:
            paymentStatus = "Payment error occurred."
        case .pending, .received:
            paymentStatus = "Payment is pending confirmation."
        case .presentToShopper:
            paymentStatus = "Additional action required. Please follow the instructions."
        }
    }

    func didFail(with error: Error, from component: Adyen.Component, session: AdyenSession) {
        paymentStatus = "Payment error: \(error.localizedDescription)"
    }
}
