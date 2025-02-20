import UIKit

public class FinancialConnectionsLite {
    /// The client secret of the Stripe `FinancialConnectionsSession` object.
    let clientSecret: String
    
    /// A URL that redirects back to your app that `FinancialConnectionsLite` can use to
    /// get back to your app after completing authentication in another app (such as bank app or Safari).
    let returnUrl: URL
    
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

        FinancialConnectionsApiClient.shared.publishableKey = publishableKey
    }
    
    @MainActor
    public func present(from viewController: UIViewController) {
        let containerViewController = ContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl
        )
        let navigationController = UINavigationController(rootViewController: containerViewController)

        let viewControllerToPresent: UIViewController
        let animated: Bool
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .formSheet
            viewControllerToPresent = navigationController
            animated = true
        } else {
            viewControllerToPresent = ModalPresentationWrapperViewController(vc: navigationController)
            animated = false
        }
        
        viewController.present(viewControllerToPresent, animated: animated)
    }
}
