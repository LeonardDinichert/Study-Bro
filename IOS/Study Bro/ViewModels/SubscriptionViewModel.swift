import SwiftUI
import StripePaymentSheet
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class SubscriptionViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var isPaymentSheetPresented = false
    @Published var statusMessage: String?
    @Published var showManage = false

    private var customerId: String?
    private var subscriptionId: String?

    @MainActor
    func subscribe(monthly: Bool) {
        Task {
            do {
                let functions = Functions.functions(region: "europe-west6")
                let resp = try await functions.httpsCallable("createSubscription").call([
                    "price_id": monthly ? "price_1RtVTfAgKukMvTmDkFEWOT8c" : "price_1RtymZAgKukMvTmD2SHnlU4w",
                    "ephemeral_key_api_version": "2024-06-20"
                ])
                guard
                    let dict = resp.data as? [String: Any],
                    let clientSecret = dict["payment_intent_client_secret"] as? String,
                    let customerId = dict["customer_id"] as? String,
                    let ephemeralKey = dict["ephemeral_key"] as? String,
                    let subscriptionId = dict["subscription_id"] as? String
                else {
                    statusMessage = "Malformed server response."
                    return
                }

                self.customerId = customerId
                self.subscriptionId = subscriptionId

                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Study Bro"
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
                config.applePay = .init(merchantId: "merchant.studybro.stripe", merchantCountryCode: "CH")

                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                self.isPaymentSheetPresented = true

                if let uid = Auth.auth().currentUser?.uid {
                    try await Firestore.firestore().collection("users").document(uid)
                        .setData(["stripe_customer_id": customerId], merge: true)
                }
            } catch {
                statusMessage = "Start failed: \(error.localizedDescription)"
            }
        }
    }

    func onPaymentCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            switch result {
            case .completed:
                if let uid = Auth.auth().currentUser?.uid,
                   let customerId = self.customerId,
                   let subscriptionId = self.subscriptionId {
                    Firestore.firestore().collection("users").document(uid).setData([
                        "is_premium": true,
                        "stripe_customer_id": customerId,
                        "stripe_subscription_id": subscriptionId,
                        "subscription_status": "active",
                        "premium_since": FieldValue.serverTimestamp()
                    ], merge: true)

                    Firestore.firestore().collection("users").document(uid)
                        .collection("transactions").addDocument(data: [
                            "type": "subscription_initial",
                            "subscription_id": subscriptionId,
                            "currency": "CHF",
                            "created": FieldValue.serverTimestamp()
                        ])
                }
                self.statusMessage = "Subscription successful."
            case .canceled:
                self.statusMessage = "Subscription canceled."
            case .failed(let error):
                self.statusMessage = "Payment failed: \(error.localizedDescription)"
            }
        }
    }

    func cancel(subscriptionId: String) {
        Task {
            do {
                let functions = Functions.functions(region: "europe-west3")
                _ = try await functions.httpsCallable("cancelSubscription").call([
                    "subscription_id": subscriptionId,
                    "cancel_at_period_end": true
                ])
                if let uid = Auth.auth().currentUser?.uid {
                    try await Firestore.firestore().collection("users").document(uid)
                        .setData(["subscription_status": "canceled", "is_premium": false], merge: true)
                }
                await MainActor.run { self.statusMessage = "Subscription canceled." }
            } catch {
                await MainActor.run { self.statusMessage = "Cancel failed: \(error.localizedDescription)" }
            }
        }
    }
}
