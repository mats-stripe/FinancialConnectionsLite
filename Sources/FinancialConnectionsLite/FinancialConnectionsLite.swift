import UIKit

public class FinancialConnectionsLite {
    public enum FlowResult {
        case success
        case canceled
        case failure(Error)
    }

    /// The client secret of the Stripe `FinancialConnectionsSession` object.
    let clientSecret: String
    
    /// A URL that redirects back to your app that `FinancialConnectionsLite` can use to
    /// get back to your app after completing authentication in another app (such as bank app or Safari).
    let returnUrl: URL
    
    /// The APIClient instance used to make requests to Stripe
    private let apiClient: FinancialConnectionsApiClient

    private var wrapperViewController: ModalPresentationWrapperViewController?
    
    /// Initializes `FinancialConnectionsLite`
    /// - Parameters:
    ///   - clientSecret: The client secret of a Stripe `FinancialConnectionsSession` object.
    ///   - publishableKey: The client's publishable key. For more info, see `https://stripe.com/docs/keys`.
    ///   - returnUrl: A URL that redirects back to your application. `FinancialConnectionsLite` uses it after completing authentication in another application (such as a bank application or Safari).
    public init(
        clientSecret: String,
        publishableKey: String,
        returnUrl: URL
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = FinancialConnectionsApiClient(publishableKey: publishableKey)
    }
    
    public func present(
        from viewController: UIViewController,
        completion: @escaping (FlowResult) -> Void
    ) {
        let containerViewController = ContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl,
            apiClient: apiClient,
            completion: { [weak self] result, controller in
                controller.dismiss(animated: true) {
                    if let wrapperViewController = self?.wrapperViewController {
                        wrapperViewController.dismiss(
                            animated: false,
                            completion: {
                                completion(result)
                            }
                        )
                    } else {
                        completion(result)
                    }
                }
            }
        )

        let navigationController = containerViewController.navController

        let toPresent: UIViewController
        let animated: Bool

        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .formSheet
            toPresent = navigationController
            animated = true
        } else {
            wrapperViewController = ModalPresentationWrapperViewController(vc: navigationController)
            toPresent = wrapperViewController!
            animated = false
        }
        
        viewController.present(toPresent, animated: animated)
    }
}
