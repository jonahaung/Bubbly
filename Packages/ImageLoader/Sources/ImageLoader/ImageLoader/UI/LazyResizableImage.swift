import Foundation
import SwiftUI

public struct LazyResizableImage<Content: View>: @MainActor Equatable, View {
	private let imageURL: URL?
	private let processors: [ImageProcessing]

	public init(url: URL?,
	            processors: [ImageProcessing] = [],
	            @ViewBuilder content: @escaping (LazyImageState) -> Content)
	{
		imageURL = url
		self.processors = processors
		self.content = content
	}

	@ViewBuilder private var content: (LazyImageState) -> Content

	public var body: some View {
		GeometryReader { geo in
			LazyImage(
				url: imageURL
			) { state in
				content(state)
			}
			.processors(
				[ImageProcessors.Resize(size: geo.size)] + processors
			)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.imageURL == rhs.imageURL
	}
}
