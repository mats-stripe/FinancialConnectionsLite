//
//  ContainerViewController.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import UIKit

class ContainerViewController: UIViewController {
    private let clientSecret: String
    private let returnUrl: URL
    private let apiClient: FinancialConnectionsApiClient

    private let spinner = UIActivityIndicatorView(style: .large)

    init(clientSecret: String, returnUrl: URL, apiClient: FinancialConnectionsApiClient) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = apiClient
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpinner()
        
        Task {
            await fetchHostedUrl()
        }
    }
    
    private func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    private func fetchHostedUrl() async {
        // Show spinner
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
        
        do {
            let manifest = try await apiClient.generateHostedUrl(
                clientSecret: clientSecret,
                returnUrl: returnUrl
            )
            await showWebView(for: manifest)
        } catch {
            await showError(error)
        }

        DispatchQueue.main.async {
            self.spinner.stopAnimating()
        }
    }
        
    private func showWebView(for manifest: LinkAccountSessionManifest) async {
        await MainActor.run {
            let authFlowViewController = AuthFlowViewController(
                hostedAuthUrl: manifest.hostedAuthURL,
                returnUrl: returnUrl
            )
            navigationController?.setViewControllers([authFlowViewController], animated: true)
        }
    }
    
    private func showError(_ error: Error) async {
        await MainActor.run {
            // Show an alert or update UI to reflect the error
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
