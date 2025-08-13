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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure fullscreen mode
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)
        
        // Hide status bar for fullscreen experience
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Hide navigation bar completely
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)
        
        // Setup progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemRed
        progressView.trackTintColor = .systemGray
        view.addSubview(progressView)
        
        // Setup web view with PWA configuration
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Enable PWA features
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false // Disable for PWA
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // Set background color
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        view.addSubview(webView)
        
        // Setup constraints for fullscreen
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add refresh gesture
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTapped), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
    }
    
    private func loadPWA() {
        // Try to load from local bundle first
        if let pwaURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PWA") {
            print("Loading PWA from local bundle: \(pwaURL)")
            webView.loadFileURL(pwaURL, allowingReadAccessTo: pwaURL.deletingLastPathComponent())
        } else {
            // Fallback to remote URL
            let fallbackURL = URL(string: "https://totally.not.spyware.lol")!
            print("Loading PWA from remote URL: \(fallbackURL)")
            webView.load(URLRequest(url: fallbackURL))
        }
    }
    
    @objc private func refreshTapped() {
        webView.reload()
        if let refreshControl = webView.scrollView.refreshControl {
            refreshControl.endRefreshing()
        }
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
        
        // Inject PWA-specific JavaScript if needed
        let pwaScript = """
        // Ensure PWA mode
        if ('standalone' in window.navigator) {
            console.log('PWA standalone mode:', window.navigator.standalone);
        }
        // Hide any remaining UI elements
        document.body.style.webkitUserSelect = 'none';
        document.body.style.webkitTouchCallout = 'none';
        """
        
        webView.evaluateJavaScript(pwaScript) { result, error in
            if let error = error {
                print("PWA script injection error: \(error)")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        
        let alert = UIAlertController(
            title: "Connection Error",
            message: "Failed to load TotallyNotSpyware: \(error.localizedDescription)\n\nPlease check your internet connection and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadPWA()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Handle external links
        if let url = navigationAction.request.url {
            if url.scheme == "tel" || url.scheme == "mailto" || url.scheme == "sms" {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
}
