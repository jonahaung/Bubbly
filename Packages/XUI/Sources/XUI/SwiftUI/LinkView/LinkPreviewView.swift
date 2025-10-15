import SwiftUI

public struct LinkPreviewView: View {

	let url: URL
	@State private var result: Result<LinkData, Error>?

	private var onCompletion: ((LinkData) -> Void)?

	public init(_ url: URL) {
		self.url = url
	}

	@ViewBuilder
	public var body: some View {
		if let result {
			switch result {
			case .success(let preview):
				if let image = preview.image {
					Image(uiImage: image)
						.resizable()
						.scaledToFit()
						.overlay(alignment: .bottom) {
							if let title = preview.subtitle {
								Text(title)
									.font(.system(size: 9, weight: .medium))
									.foregroundStyle(.white.gradient)
									.padding(4)
							}
						}.onAppear {
							onCompletion?(preview)
						}
				}
			case .failure(let failure):
				ContentUnavailableView(failure.localizedDescription, systemImage: "xmark.circle.fill")
			}
		} else {
			ProgressView().controlSize(.mini)
				.task {
					let fetcher = await FetcherPool.shared.fetcher(of: LinkData.self)
					do {
						let data = try await fetcher.fetch(url)
						await MainActor.run {
							self.result = .success(data)
						}
					} catch {
						await MainActor.run {
							self.result = .failure(error)
						}
					}
				}
				.onDisappear {
					Task {
						let fetcher = await FetcherPool.shared.fetcher(of: LinkData.self)
						await fetcher.cancelFetch(url)
					}
				}
		}
	}

	public func onCompletion(_ closure: @escaping (LinkData) -> Void) -> Self {
		var copy = self
		copy.onCompletion = closure
		return copy
	}
}
