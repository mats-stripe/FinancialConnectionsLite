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

    // Strong references to prevent deallocation
    private var containerViewController: ContainerViewController?
    private var navigationController: UINavigationController?
    private var wrapperViewController: ModalPresentationWrapperViewController?
    private var completionHandler: ((FlowResult) -> Void)?
    
    // Static collection to retain instances
    private static var activeInstances = Set<FinancialConnectionsLite>()

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
        // Retain self in the static collection
        Self.activeInstances.insert(self)
        
        // Store the completion handler
        self.completionHandler = { result in
            // Call original completion
            completion(result)
            
            // Remove self from active instances
            Self.activeInstances.remove(self)
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
        self.containerViewController = containerVC

        let navController = UINavigationController(rootViewController: containerVC)
        navController.navigationBar.isHidden = true
        navController.isModalInPresentation = true
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
        // First dismiss the container controller
        let controller = self.wrapperViewController ?? self.navigationController
        controller?.dismiss(animated: true) { [weak self] in
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
        self.containerViewController = nil
        self.navigationController = nil
        self.wrapperViewController = nil
        self.completionHandler = nil
    }
}

extension FinancialConnectionsLite: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: FinancialConnectionsLite, rhs: FinancialConnectionsLite) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
