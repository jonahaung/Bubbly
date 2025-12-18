import SwiftUI
import WebKit

// public struct WebView: UIViewRepresentable {
//    public let url: URL?
//
//    public init(url: URL?) {
//        self.url = url
//    }
//
//    public func makeUIView(context: Context) -> WKWebView {
//        let config = WKWebViewConfiguration()
//        config.allowsInlineMediaPlayback = true
//        let webView = WKWebView(frame: .zero, configuration: config)
//        webView.navigationDelegate = context.coordinator
//        webView.allowsBackForwardNavigationGestures = true
//        if let url {
//            webView.load(URLRequest(url: url))
//        }
//        return webView
//    }
//
//    public func updateUIView(_ uiView: WKWebView, context _: Context) {
//        // Reload when URL changes
//        if let url {
//            if uiView.url != url {
//                uiView.load(URLRequest(url: url))
//            }
//        } else {
//            uiView.stopLoading()
//            uiView.loadHTMLString("", baseURL: nil)
//        }
//    }
//
//    public func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    public class Coordinator: NSObject, WKNavigationDelegate {
//        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//            #if DEBUG
//            print("WebView navigation failed: \(error.localizedDescription)")
//            #endif
//        }
//
//        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//            #if DEBUG
//            print("WebView provisional navigation failed: \(error.localizedDescription)")
//            #endif
//        }
//    }
// }
