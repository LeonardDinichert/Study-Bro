import SwiftUI
import Foundation
import FirebaseCoreExtension
import StripePaymentSheet
import Stripe
import FirebaseAuth

// 1. Decode your backend’s subscription-creation response
struct SubscriptionsResponse: Decodable {
    let subscriptionId: String
    let clientSecret: String
}

@MainActor
final class SubscriptionViewModel: NSObject, ObservableObject {
    @Published var paymentStatus: String?
    private var paymentSheet: PaymentSheet?

    // 2. Create or fetch a Stripe Customer
    func subscribe(email: String) {
        Task {
            var req = URLRequest(url: URL(string: "http://localhost:4242/create-customer")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try! JSONEncoder().encode(["email": email])
            let (data, _) = try! await URLSession.shared.data(for: req)
            let json = try! JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let customerId = json?["customerId"] as? String else {
                paymentStatus = "Failed to parse customer ID"
                return
            }
            // 3. Once you have the customer, start the subscription flow
            startPayment(priceId: "your_price_id_here", customerId: customerId)
        }
    }

    // 4. Call your backend to create a Subscription and retrieve client secret
    private func createSubscription(priceId: String, customerId: String) async -> SubscriptionsResponse {
        var req = URLRequest(url: URL(string: "http://localhost:4242/create-subscription")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try! JSONEncoder().encode([
            "customerId": customerId,
            "priceId": priceId
        ])
        let (data, _) = try! await URLSession.shared.data(for: req)
        return try! JSONDecoder().decode(SubscriptionsResponse.self, from: data)
    }

    // 5. Initialize and present Stripe’s PaymentSheet
    func startPayment(priceId: String, customerId: String) {
        Task {
            let resp = await createSubscription(priceId: priceId, customerId: customerId)
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Your Merchant"
            // (Optional) config.customer = .init(id: customerId, ephemeralKeySecret: ...)
            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: resp.clientSecret,
                configuration: config
            )
            DispatchQueue.main.async {
                self.paymentSheet?.present(from: UIApplication.shared.windows.first!.rootViewController!) { result in
                    switch result {
                    case .completed:
                        self.paymentStatus = "Payment complete ✅"
                    case .canceled:
                        self.paymentStatus = "Payment canceled ⚠️"
                    case .failed(let error):
                        self.paymentStatus = "Payment failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
