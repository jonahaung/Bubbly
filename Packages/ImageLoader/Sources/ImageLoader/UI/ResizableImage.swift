//
//  ResizableImage.swift
//  ImageLoader
//
//  Created by Aung Ko Min on 26/8/25.
//

import SwiftUI

@MainActor
public struct ResizableImage: View, @MainActor Equatable {
    private let imageURL: URL?
    private let processors: [ImageProcessing]

    public init(_ urlString: String?, processors: [ImageProcessing] = []) {
        if let urlString {
            imageURL = URL(string: urlString)
        } else {
            imageURL = nil
        }
        self.processors = processors
    }

    public var body: some View {
        LazyImage(
            url: imageURL,
            transaction: .init()
        ) { state in
            Group {
                if state.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.gray)
                } else {
                    switch state.result {
                    case let .success(success):
                        Image(uiImage: success.image)
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo.circle.fill")
                            .resizable()
                            .foregroundStyle(.tertiary)
                    case .none:
                        Image(systemName: "photo.circle.fill")
                            .resizable()
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .processors(
            processors
        )
    }

    public static func == (lhs: ResizableImage, rhs: ResizableImage) -> Bool {
        lhs.imageURL == rhs.imageURL
    }
}
