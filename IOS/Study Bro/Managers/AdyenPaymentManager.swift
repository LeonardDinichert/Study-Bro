import Foundation
import AdyenDropIn
import AdyenSession
import Adyen
import FirebaseFunctions
import UIKit

@MainActor
final class AdyenPaymentManager: @MainActor NSObject, @MainActor PresentationDelegate {
    func present(component: any Adyen.PresentableComponent) {
        if let presenter = Utilities.shared.topViewController() {
            presenter.present(component.viewController, animated: true)
        }
    }
    
    static let shared = AdyenPaymentManager()
    private override init() {}

    private let clientKey = "test_WHDOQ6JHV5CDZMG5ZAZOSGAY5IWUDLJJ"

    private lazy var apiContext: APIContext = {
        return try! APIContext(environment: Environment.test, clientKey: clientKey)
    }()

    private lazy var adyenContext: AdyenContext = {
        let amount = Amount(value: 1000, currencyCode: "CHF")
        let payment = Payment(amount: amount, countryCode: "CH")
        return AdyenContext(apiContext: apiContext, payment: payment)
    }()

    private var currentSession: AdyenSession?
    private var dropInComponent: DropInComponent?

    func startSubscription(paymentAmount: Int, delegate: AdyenSessionDelegate) {
        print("[AdyenPaymentManager] startSubscription called with amount: \(paymentAmount)")
        print("[AdyenPaymentManager] Calling createPaymentSession Cloud Function...")
        Functions.functions(region: "europe-west3").httpsCallable("createPaymentSession").call { [weak self] result, error in
            print("[AdyenPaymentManager] Received response from createPaymentSession. Error: \(String(describing: error)), Result: \(String(describing: result))")
            guard
                error == nil,
                let data = result?.data as? [String: Any],
                let sessionId = data["id"] as? String,
                let sessionData = data["sessionData"] as? String,
                let self = self
            else {
                print("Failed to create payment session: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("[AdyenPaymentManager] Successfully got sessionId: \(sessionId), sessionData: (hidden)")
            let configuration = AdyenSession.Configuration(sessionIdentifier: sessionId, initialSessionData: sessionData, context: self.adyenContext)
            print("[AdyenPaymentManager] Initializing AdyenSession...")
            AdyenSession.initialize(with: configuration, delegate: delegate, presentationDelegate: self) { initResult in
                print("[AdyenPaymentManager] AdyenSession.initialize completion called")
                switch initResult {
                case let .success(session):
                    print("[AdyenPaymentManager] AdyenSession initialized successfully. Presenting DropIn...")
                    self.currentSession = session
                    Task { @MainActor in
                        self.presentDropIn(using: session)
                    }
                case let .failure(error):
                    print("[AdyenPaymentManager] Adyen session initialization failed: \(error)")
                    print("Adyen session init failed: \(error)")
                }
            }
        }
    }

    @MainActor private func presentDropIn(using session: AdyenSession) {
        let dropInConfig = DropInComponent.Configuration()
        dropInConfig.card.showsHolderNameField = true
        dropInConfig.card.showsStorePaymentMethodField = false
        dropInConfig.actionComponent.twint = .init(callbackAppScheme: "studybro-payments://adyen")

        let dropIn = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                     context: adyenContext,
                                     configuration: dropInConfig)
        dropInComponent = dropIn
        dropIn.delegate = session

        DispatchQueue.main.async {
            if let presenter = Utilities.shared.topViewController() {
                presenter.present(dropIn.viewController, animated: true)
            }
        }
    }

    // MARK: - PresentationDelegate
    func present(_ component: PresentableComponent, from presentingViewController: UIViewController?) {
        let presenter = presentingViewController ?? Utilities.shared.topViewController()
        presenter?.present(component.viewController, animated: true)
    }

    func dismiss(_ component: PresentableComponent, completion: (() -> Void)?) {
        component.viewController.dismiss(animated: true, completion: completion)
    }
}
