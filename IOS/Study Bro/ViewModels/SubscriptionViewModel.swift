import Foundation
import AdyenSession
import FirebaseCoreExtension
import UIKit
import Adyen
import FirebaseAuth

@MainActor
final class SubscriptionViewModel: NSObject, ObservableObject, AdyenSessionDelegate {
    
    @Published var paymentStatus: String?

    func subscribe(paymentAmount: Int = 1000) {
        AdyenPaymentManager.shared.startSubscription(paymentAmount: paymentAmount, delegate: self)
    }

    func didComplete(with result: AdyenSessionResult, component: Adyen.Component, session: AdyenSession) {
        switch result.resultCode {
        case .authorised:
            paymentStatus = "Subscription purchase successful! 🎉"
            markSubscriptionActive(uid: Auth.auth().currentUser?.uid ?? "unknown", nextPayment: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()) { error in
                if let error = error {
                    print("Error marking subscription active: \(error.localizedDescription)")
                }
            }
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

import FirebaseFirestore

func markSubscriptionActive(uid: String, nextPayment: Date, completion: @escaping (Error?) -> Void) {
  let db = Firestore.firestore()
  let subRef = db.collection("users").document(uid).collection("subscription").document("status")

  let data: [String: Any] = [
    "status": "active",
    "nextPaymentDate": Timestamp(date: nextPayment)
  ]

  subRef.setData(data, merge: true) { error in
    completion(error)
  }
}
