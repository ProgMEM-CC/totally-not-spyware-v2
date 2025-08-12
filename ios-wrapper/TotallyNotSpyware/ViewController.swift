import UIKit
import WebKit

class ViewController: UIViewController {
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPWA()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Setup web view
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(webView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup navigation bar
        navigationItem.title = "TotallyNotSpyware v2"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    private func loadPWA() {
        // Load the PWA from local bundle
        if let pwaURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PWA") {
            webView.loadFileURL(pwaURL, allowingReadAccessTo: pwaURL.deletingLastPathComponent())
        } else {
            // Fallback to remote URL (for development)
            let fallbackURL = URL(string: "https://your-pwa-domain.com")!
            webView.load(URLRequest(url: fallbackURL))
        }
    }
    
    @objc private func refreshTapped() {
        webView.reload()
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(1.0, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.progressView.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to load PWA: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
