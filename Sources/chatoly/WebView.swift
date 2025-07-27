import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: String
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Set a modern user agent to avoid YouTube's browser version check
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // Enable swipe gestures for navigation
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject CSS to make chat more suitable for overlay (future enhancement)
            let css = """
                body {
                    background: rgba(0, 0, 0, 0.8) !important;
                }
                """
            
            let script = """
                var style = document.createElement('style');
                style.innerHTML = '\(css)';
                document.head.appendChild(style);
                """
            
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}