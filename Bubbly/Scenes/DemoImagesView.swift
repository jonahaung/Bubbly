//
//  DemoImagesView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 4/9/25.
//

import SwiftUI
import XUI
import Services
import ImageLoader
import PassKit

struct DemoImagesView: View {
    var body: some View {
		ScrollView {
			let chunks = DemoImages.demoPhotosURLs.chunked(into: 3)
			LazyVStack {
				ForEach(chunks.enumerated, id: \.0) { index, urls in
					Section {
						ComposedLayout(topColumns: 1, bottomColumns: 2) {
							ForEach(
								urls.enumerated,
								id: \.0
							) { i, url in
								LinkPreviewView(url)
									.id(i)
							}
						}
						.cornerRadius(12)
					}
					.intersperse {
						Divider()
					}
				}
			}
		}
		.contentMargins(8, for: .scrollContent)
		.navigationTitle("Demo Images")
    }

	struct DemoImageCell: View {
		let url: URL
		@State private var aspectRatio: CGFloat?

		var body: some View {
			ZStack {
				LazyImage(url: url) { state in
					state.image?
						.resizable()
						.scaledToFit()
				}
			}
		}
	}
}
extension Array {
	func chunked(into size: Int) -> [[Element]] {
		guard size > 0 else { return [self] }
		var result: [[Element]] = []
		var index = 0
		while index < self.count {
			let end = Swift.min(index + size, self.count)
			result.append(Array(self[index..<end]))
			index += size
		}
		return result
	}
}
