//
//  DemoImagesView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 4/9/25.
//

import ImageLoader
import PassKit
import Services
import SwiftUI
import XUI

struct DemoImagesView: View {
    var body: some View {
        ScrollView {
            let chunks = DemoImages.demoPhotosURLs.chunked(into: 3)
            LazyVStack {
                ForEach(chunks.enumerated, id: \.0) { _, urls in
                    Section {
                        ComposedLayout(topColumns: 1, bottomColumns: 2) {
                            ForEach(
                                urls.enumerated,
                                id: \.0
                            ) { index, url in
                                LinkPreviewView(url)
                                    .id(index)
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
        while index < count {
            let end = Swift.min(index + size, count)
            result.append(Array(self[index ..< end]))
            index += size
        }
        return result
    }
}
