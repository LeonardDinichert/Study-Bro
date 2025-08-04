import Foundation
import Adyen
import FirebaseFunctions
import UIKit

final class AdyenPaymentManager: NSObject, PresentationDelegate {
    static let shared = AdyenPaymentManager()
    private override init() {}

    private let clientKey = "<YOUR_ADYEN_CLIENT_KEY>"

    private lazy var apiContext: APIContext = {
        APIContext(clientKey: clientKey, environment: .test)
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
                let sessionData = data["sessionData"] as? String
            else {
                print("Failed to create payment session: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let configuration = AdyenSession.Configuration(sessionIdentifier: sessionId, initialSessionData: sessionData)
            AdyenSession.initialize(with: configuration, delegate: delegate, presentationDelegate: self) { initResult in
                switch initResult {
                case let .success(session):
                    self?.currentSession = session
                    self?.presentDropIn(using: session)
                case let .failure(error):
                    print("Adyen session init failed: \(error)")
                }
            }
        }
    }

    private func presentDropIn(using session: AdyenSession) {
        var dropInConfig = DropInComponent.Configuration(apiContext: apiContext)
        dropInConfig.card.showsHolderNameField = true
        dropInConfig.card.showsStorePaymentMethodField = false
        dropInConfig.card.storePaymentMethod = true
        dropInConfig.actionComponent.twint = .init(callbackAppScheme: "studybro-payments://")

        let dropIn = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                     context: adyenContext,
                                     configuration: dropInConfig)
        dropInComponent = dropIn
        dropIn.delegate = session
        if let presenter = Utilities.shared.topViewController(), let viewController = dropIn.viewController {
            presenter.present(viewController, animated: true)
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
