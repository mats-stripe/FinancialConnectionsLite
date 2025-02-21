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
    private let completion: ((FinancialConnectionsLite.FlowResult) -> Void)

    private let spinner = UIActivityIndicatorView(style: .large)

    init(
        clientSecret: String,
        returnUrl: URL,
        apiClient: FinancialConnectionsApiClient,
        completion: @escaping ((FinancialConnectionsLite.FlowResult) -> Void)
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = apiClient
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
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
        let authFlowViewController = AuthFlowViewController(
            hostedAuthUrl: manifest.hostedAuthURL,
            returnUrl: returnUrl,
            completion: { [weak self] result, controller in
                controller.dismiss(animated: true)
                self?.completion(result)
            }
        )
        navigationController?.setViewControllers([authFlowViewController], animated: false)
    }
    
    private func showError(_ error: Error) async {
        // Show an alert or update UI to reflect the error
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
