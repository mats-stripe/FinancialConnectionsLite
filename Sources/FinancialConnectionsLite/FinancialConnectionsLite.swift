import UIKit

public class FinancialConnectionsLite: NSObject {
    public enum FlowResult {
        case success
        case canceled
        case failure(Error)
    }

    /// The client secret of the Stripe `FinancialConnectionsSession` object.
    let clientSecret: String

    /// A URL that redirects back to your app that `FinancialConnectionsLite` can use to
    /// get back to your app after completing authentication in another app (such as a bank app or Safari).
    let returnUrl: URL
    
    /// The APIClient instance used to make requests to Stripe
    private let apiClient: FinancialConnectionsApiClient

    // Strong references to prevent deallocation
    private var navigationController: UINavigationController?
    private var wrapperViewController: ModalPresentationWrapperViewController?
    private var completionHandler: ((FlowResult) -> Void)?

    // Static reference to hold the active instance
    private static var activeInstance: FinancialConnectionsLite?

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
        // Store self as the active instance
        Self.activeInstance = self

        self.completionHandler = { result in
            // Call original completion
            completion(result)
            // Clear the active instance reference
            Self.activeInstance = nil
        }

        let containerVC = ContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl,
            apiClient: apiClient,
            completion: { [weak self] result in
                guard let self else { return }
                self.handleFlowCompletion(result: result)
            }
        )

        let navController = UINavigationController(rootViewController: containerVC)
        navController.navigationBar.isHidden = true
        navController.presentationController?.delegate = self
        self.navigationController = navController

        let toPresent: UIViewController
        let animated: Bool

        if UIDevice.current.userInterfaceIdiom == .pad {
            navController.modalPresentationStyle = .formSheet
            toPresent = navController
            animated = true
        } else {
            wrapperViewController = ModalPresentationWrapperViewController(vc: navController)
            toPresent = wrapperViewController!
            animated = false
        }

        viewController.present(toPresent, animated: animated)
    }
    
    private func handleFlowCompletion(result: FlowResult) {
        // First dismiss the navigation controller
        self.navigationController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            // Dismiss the wrapper if it exists
            if let wrapper = self.wrapperViewController {
                wrapper.dismiss(animated: false) { [weak self] in
                    guard let self, let completion = self.completionHandler else { return }
                    
                    // Clear references and call the completion handler
                    self.cleanupReferences()
                    completion(result)
                }
            } else {
                // No wrapper, just clean up and call completion directly
                guard let completion = self.completionHandler else { return }
                self.cleanupReferences()
                completion(result)
            }
        }
    }
    
    private func cleanupReferences() {
        // Clear all references to avoid memory leaks
        self.navigationController = nil
        self.wrapperViewController = nil
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension FinancialConnectionsLite: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showDismissConfirmation(presentedBy: presentationController.presentedViewController)
    }
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Return false to prevent automatic dismissal
        return false
    }
    
    private func showDismissConfirmation(presentedBy viewController: UIViewController) {
        let alertController = UIAlertController(
            title: "Are you sure you want to exit?",
            message: "You haven't finished linking you bank account and all progress will be lost.",
            preferredStyle: .alert
        )
        
        // Add cancel option
        alertController.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))

        // Add confirm option
        alertController.addAction(UIAlertAction(
            title: "Yes, exit",
            style: .default,
            handler: { [weak self] _ in
                guard let self = self else { return }
                self.handleFlowCompletion(result: .canceled)
            }
        ))
        
        viewController.present(alertController, animated: true)
    }
}
