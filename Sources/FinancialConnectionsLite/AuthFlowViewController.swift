//
//  AuthFlowViewController.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import AuthenticationServices
import UIKit
import WebKit

class AuthFlowViewController: UIViewController {
    private let hostedAuthUrl: URL
    private let returnUrl: URL
    private var webAuthenticationSession: ASWebAuthenticationSession?

    init(hostedAuthUrl: URL, returnUrl: URL) {
        self.hostedAuthUrl = hostedAuthUrl
        self.returnUrl = returnUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        isModalInPresentation = true

        let webView = WKWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration()
        )
        let request = URLRequest(url: hostedAuthUrl)
        webView.load(request)

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        webView.uiDelegate = self
    }
}

extension AuthFlowViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Check if the link is attempting to open in a new window.
        // This is typically the case for a banking partner's authentication flow.
        let isAttemptingToOpenLinkInNewWindow = navigationAction.targetFrame?.isMainFrame != true

        if isAttemptingToOpenLinkInNewWindow, let url = navigationAction.request.url {
            // Attempt to open the URL as a universal link.
            // Universal links allow apps on the device to handle specific URLs directly.
            UIApplication.shared.open(
                url,
                options: [.universalLinksOnly: true],
                completionHandler: { [weak self] success in
                    guard let self else { return }
                    if success {
                        // App-to-app flow:
                        // The URL was successfully opened in a banking application that supports universal links.
                        print("Successfully opened the authentication URL in a bank app: \(url)")
                    } else {
                        // Fallback for when no compatible bank app is found:
                        // Create an `ASWebAuthenticationSession` to handle the authentication in a secure in-app browser
                        self.launchInSecureBrowser(url: url)
                    }
                })
        }
        return nil
    }

    private func launchInSecureBrowser(url: URL) {
        let webAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: returnUrl.scheme,
            completionHandler: { redirectURL, error in
                if let error {
                    if
                        (error as NSError).domain == ASWebAuthenticationSessionErrorDomain,
                        (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                    {
                        print("User manually closed the browser by pressing 'Cancel' at the top-left corner.")
                    } else {
                        print("Received an error from ASWebAuthenticationSession: \(error)")
                    }
                } else {
                    // ======================
                    // IMPORTANT NOTE:
                    // ======================
                    // The browser will automatically close when
                    // the `callbackURLScheme` is called.
                    print("Received a redirect URL: \(redirectURL?.absoluteString ?? "null")")
                }
            }
        )
        self.webAuthenticationSession = webAuthenticationSession
        webAuthenticationSession.presentationContextProvider = self
        webAuthenticationSession.prefersEphemeralWebBrowserSession = true // disable the initial Apple alert
        webAuthenticationSession.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthFlowViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
