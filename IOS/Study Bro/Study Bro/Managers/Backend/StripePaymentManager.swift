import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

enum CustomError: Error {
    case invalidURL
    case emptyResponse
}

class SubscriptionManager {
    static let shared = SubscriptionManager()
    private let db = Firestore.firestore()
    
    // 1. Call backend to create subscription
    @MainActor
    func createSubscriptionCheckout(priceId: String, completion: @escaping (Result<CheckoutResponse, Error>) -> Void) {
        // Prepare the request to your Cloud Function endpoint
        guard let url = URL(string: "https://createsubscription-lyg2ibnyqq-oa.a.run.app") else {
            return completion(.failure(CustomError.invalidURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Include the price ID and user’s UID (or token) in the request body
        let body = [
            "priceId": priceId,
            "uid": Auth.auth().currentUser?.uid ?? ""   // ensure user is logged in
        ]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                Task { @MainActor in completion(.failure(err)) }
                return
            }
            guard let data = data else {
                Task { @MainActor in completion(.failure(CustomError.emptyResponse)) }
                return
            }
            Task { @MainActor in
                do {
                    let checkoutInfo = try JSONDecoder().decode(CheckoutResponse.self, from: data)
                    completion(.success(checkoutInfo))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // 2. Update Firestore with subscription info
    func saveSubscriptionInfo(uid: String, customerId: String, subscriptionId: String, status: String, productId: String) {
        let userRef = db.collection("user").document(uid)
        // Update user document with subscription details
        userRef.updateData([
            "is_premium": true,
            "stripe_customer_id": customerId,
            "stripe_subscription_id": subscriptionId,
            "subscription_status": status,         // e.g. "active" (Stripe status)
            "premium_product_id": productId,
            "premium_since": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error saving subscription info: \(error)")
            }
        }
    }
    
    // 3. Record a transaction in Firestore
    func saveTransaction(uid: String, amount: Int, currency: String, transactionId: String, type: String = "subscription") {
        let transRef = db.collection("user").document(uid)
                         .collection("transactions").document(transactionId)
        transRef.setData([
            "amount": amount,
            "currency": currency,
            "date": FieldValue.serverTimestamp(),
            "type": type,
            "stripe_payment_intent_id": transactionId
        ]) { error in
            if let error = error {
                print("Error saving transaction: \(error)")
            }
        }
    }
    
    // 4. Cancel subscription via backend
    func cancelSubscription(subscriptionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://cancelsubscription-lyg2ibnyqq-oa.a.run.app") else {
            return completion(.failure(CustomError.invalidURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["subscriptionId": subscriptionId])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                completion(.failure(err))
                return
            }
            // On success, update Firestore status to canceled
            // (Assuming the cloud function cancels the subscription on Stripe)
            // You could also refresh the subscription status by fetching from Stripe if needed.
            completion(.success(()))
        }.resume()
    }
}

// Define the expected response structure from the backend for convenience
struct CheckoutResponse: Codable {
    
    let customerId: String
    let ephemeralKey: String
    let paymentIntentClientSecret: String
    let subscriptionId: String
}
