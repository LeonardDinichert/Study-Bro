import SwiftUI
import StripePaymentSheet
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Combine

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
                    "priceId": monthly ? "price_1RtVTfAgKukMvTmDkFEWOT8c" : "price_1RtymZAgKukMvTmD2SHnlU4w",
                    "ephemeralKeyApiVersion": "2024-06-20"
                ])
                guard
                    let dict = resp.data as? [String: Any],
                    let clientSecret = dict["paymentIntentClientSecret"] as? String,
                    let customerId = dict["customerId"] as? String,
                    let ephemeralKey = dict["ephemeralKey"] as? String,
                    let subscriptionId = dict["subscriptionId"] as? String
                else {
                    statusMessage = "Malformed server response."
                    return
                }

                self.customerId = customerId
                self.subscriptionId = subscriptionId

                var config = PaymentSheet.Configuration()
                config.returnURL = "studybro-payments://stripe"
                config.merchantDisplayName = "Study Bro"
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
                config.applePay = .init(merchantId: "merchant.studybro.stripe", merchantCountryCode: "CH")

                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                if let sheet = self.paymentSheet, let presenter = Self.topMostViewController() {
                    sheet.present(from: presenter) { result in
                        self.onPaymentCompletion(result: result)
                    }
                } else {
                    self.statusMessage = "UI error: no presenter available."
                }

                if let uid = Auth.auth().currentUser?.uid {
                    try await Firestore.firestore().collection("users").document(uid)
                        .setData(["stripe_customer_id": customerId], merge: true)
                }
            } catch {
                statusMessage = "Start failed: \(error.localizedDescription)"
                print("Start failed: \(error.localizedDescription)")
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
                let functions = Functions.functions(region: "europe-west6")
                _ = try await functions.httpsCallable("cancelSubscription").call([
                    "subscriptionId": subscriptionId,
                    "cancelAtPeriodEnd": true
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

private extension SubscriptionViewModel {
    static func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController { return topMostViewController(base: selected) }
        if let presented = base?.presentedViewController { return topMostViewController(base: presented) }
        return base
    }
}
