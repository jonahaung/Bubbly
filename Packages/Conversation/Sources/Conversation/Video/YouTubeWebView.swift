//  YouTubeWebView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import WebKit
    import SwiftUI

    struct YouTubeWebView: UIViewRepresentable {
        let videoID: String
        let onError: () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onError: onError)
        }

        func makeUIView(context: Context) -> WKWebView {
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = context.coordinator
            webView.scrollView.isScrollEnabled = false
            return webView
        }

        func updateUIView(_ webView: WKWebView, context _: Context) {
            let html = """
            <html>
            <body style="margin:0;background:black;">
              <iframe
            	src="https://www.youtube.com/embed/\(videoID)?playsinline=1"
            	width="100%"
            	height="100%"
            	frameborder="0"
            	allow="autoplay; encrypted-media"
            	allowfullscreen>
              </iframe>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        }

        final class Coordinator: NSObject, WKNavigationDelegate {
            let onError: () -> Void

            init(onError: @escaping () -> Void) {
                self.onError = onError
            }

            func webView(
                _: WKWebView,
                didFail _: WKNavigation!,
                withError _: Error
            ) {
                onError()
            }

            func webView(
                _: WKWebView,
                didFailProvisionalNavigation _: WKNavigation!,
                withError _: Error
            ) {
                onError()
            }
        }
    }

#endif
