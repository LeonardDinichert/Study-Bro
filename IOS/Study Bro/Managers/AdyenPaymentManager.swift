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

    private let clientKey = "<YOUR_ADYEN_CLIENT_KEY>"

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
        Functions.functions().httpsCallable("createPaymentSession").call { [weak self] result, error in
            guard
                error == nil,
                let data = result?.data as? [String: Any],
                let sessionId = data["sessionId"] as? String,
                let sessionData = data["sessionData"] as? String,
                let self = self
            else {
                print("Failed to create payment session: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let configuration = AdyenSession.Configuration(sessionIdentifier: sessionId, initialSessionData: sessionData, context: self.adyenContext)
            AdyenSession.initialize(with: configuration, delegate: delegate, presentationDelegate: self) { initResult in
                switch initResult {
                case let .success(session):
                    self.currentSession = session
                    Task { @MainActor in
                        self.presentDropIn(using: session)
                    }
                case let .failure(error):
                    print("Adyen session init failed: \(error)")
                }
            }
        }
    }

    @MainActor private func presentDropIn(using session: AdyenSession) {
        var dropInConfig = DropInComponent.Configuration()
        dropInConfig.card.showsHolderNameField = true
        dropInConfig.card.showsStorePaymentMethodField = false
        dropInConfig.actionComponent.twint = .init(callbackAppScheme: "studybro-payments://")

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

