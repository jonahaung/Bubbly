// The MIT License (MIT)
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Combine
import SwiftUI
import UIKit

@MainActor
public struct LazyImage<Content: View>: View {
    @State private var viewModel = FetchImage()

    private var context: LazyImageContext?
    private var makeContent: ((LazyImageState) -> Content)?
    private var transaction: Transaction
    private var pipeline: ImagePipeline = .shared
    private var onStart: ((ImageTask) -> Void)?
    private var onDisappearBehavior: DisappearBehavior? = .cancel
    private var onCompletion: ((Result<ImageResponse, Error>) -> Void)?

    public init(url: URL?) where Content == Image {
        self.init(request: url.map { ImageRequest(url: $0) })
    }

    public init(request: ImageRequest?) where Content == Image {
        context = request.map(LazyImageContext.init)
        transaction = Transaction(animation: .easeIn)
    }

    public init(
        url: URL?,
        transaction: Transaction = Transaction(animation: nil),
        @ViewBuilder content: @escaping (LazyImageState) -> Content
    ) {
        self.init(request: url.map { ImageRequest(url: $0) }, transaction: transaction, content: content)
    }

    public init(
        request: ImageRequest?,
        transaction: Transaction = Transaction(animation: nil),
        @ViewBuilder content: @escaping (LazyImageState) -> Content
    ) {
        context = request.map { LazyImageContext(request: $0) }
        self.transaction = transaction
        makeContent = content
    }

    public func processors(_ processors: [any ImageProcessing]?) -> Self {
        map { $0.context?.request.processors = processors ?? [] }
    }

    public func priority(_ priority: ImageRequest.Priority?) -> Self {
        map { $0.context?.request.priority = priority ?? .normal }
    }

    public func pipeline(_ pipeline: ImagePipeline) -> Self {
        map { $0.pipeline = pipeline }
    }

    public enum DisappearBehavior {
        case cancel
        case lowerPriority
    }

    public func onStart(_ closure: @escaping (ImageTask) -> Void) -> Self {
        map { $0.onStart = closure }
    }

    public func onDisappear(_ behavior: DisappearBehavior?) -> Self {
        map { $0.onDisappearBehavior = behavior }
    }

    public func onCompletion(_ closure: @escaping (Result<ImageResponse, Error>) -> Void) -> Self {
        map { $0.onCompletion = closure }
    }

    private func map(_ closure: (inout LazyImage) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }

    public var body: some View {
        ZStack {
            if let makeContent {
                makeContent(viewModel)
            } else {
                makeDefaultContent(for: viewModel)
            }
        }
        .onAppear { onAppear() }
        .onDisappear { onDisappear() }
        .onChange(of: context) { _, newValue in
            viewModel.load(newValue?.request)
        }
    }

    @ViewBuilder
    private func makeDefaultContent(for state: LazyImageState) -> some View {
        if let image = state.image {
            image
        } else {
            EmptyView()
        }
    }

    private func onAppear() {
        viewModel.transaction = transaction
        viewModel.pipeline = pipeline
        viewModel.onStart = onStart
        viewModel.onCompletion = onCompletion
        viewModel.load(context?.request)
    }

    private func onDisappear() {
        guard let behavior = onDisappearBehavior else { return }
        switch behavior {
        case .cancel:
            viewModel.cancel()
        case .lowerPriority:
            viewModel.priority = .veryLow
        }
    }
}

private struct LazyImageContext: Equatable {
    var request: ImageRequest

    static func == (lhs: LazyImageContext, rhs: LazyImageContext) -> Bool {
        let lhs = lhs.request
        let rhs = rhs.request
        return lhs.preferredImageId == rhs.preferredImageId &&
            lhs.priority == rhs.priority &&
            lhs.processors == rhs.processors &&
            lhs.priority == rhs.priority &&
            lhs.options == rhs.options
    }
}

#if DEBUG
    struct LazyImage_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                LazyImageDemoView()
                    .previewDisplayName("LazyImage")

                LazyImage(url: URL(string: "https://kean.blog/images/pulse/01.png"))
                    .previewDisplayName("LazyImage (Default)")

                AsyncImage(url: URL(string: "https://kean.blog/images/pulse/01.png"))
                    .previewDisplayName("AsyncImage")
            }
        }
    }

    private struct LazyImageDemoView: View {
        @State var url = URL(string: "https://kean.blog/images/pulse/01.png")
        @State var isBlured = false
        @State var imageViewId = UUID()

        var body: some View {
            VStack {
                Spacer()

                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    }
                }
                .processors(isBlured ? [ImageProcessors.GaussianBlur()] : [])
                .id(imageViewId)

                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    Button("Change Image") {
                        if url == URL(string: "https://kean.blog/images/pulse/01.png") {
                            url = URL(string: "https://kean.blog/images/pulse/02.png")
                        } else {
                            url = URL(string: "https://kean.blog/images/pulse/01.png")
                        }
                    }
                    Button("Retry") { imageViewId = UUID() }
                    Toggle("Apply Blur", isOn: $isBlured)
                }
                .padding()
                .background(Material.ultraThick)
            }
        }
    }
#endif
