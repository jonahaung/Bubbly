//
//  YouTubeView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 6/1/26.
//

import SwiftUI
import WebKit

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

	func updateUIView(_ webView: WKWebView, context: Context) {
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

		func webView(_ webView: WKWebView,
		             didFail navigation: WKNavigation!,
		             withError error: Error)
		{
			onError()
		}

		func webView(_ webView: WKWebView,
		             didFailProvisionalNavigation navigation: WKNavigation!,
		             withError error: Error)
		{
			onError()
		}
	}
}
