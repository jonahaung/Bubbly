//
//  SwiftUIView.swift
//
//
//  Created by Aung Ko Min on 3/6/24.
//

import SwiftUI

@available(iOS 18.0, *)
public struct LodableScrollView<Content: View>: View {

    public typealias Action = @Sendable () async -> Void

    private let axis: Axis.Set
    private let showsIndicators: Bool
    private let content: () -> Content
    private let onLoadMore: Action
    @Binding private var isLoadingMore: Bool

    public init(
        _ axis: Axis.Set = .vertical,
        showsIndicators: Bool = false,
        isLoadingMore: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        onLoadMore: @escaping Action
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.content = content
        self.onLoadMore = onLoadMore
        _isLoadingMore = isLoadingMore
    }

    public var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            content()
        }
        .onScrollGeometryChange(for: Bool.self, of: { geometry in
            let offsetY = geometry.contentOffset.y + geometry.bounds.height*2
            let target = geometry.contentSize.height-geometry.contentInsets.bottom
            let canLoadMore = offsetY > target
            return canLoadMore
        }, action: { oldValue, newValue in
            guard oldValue != newValue && newValue && isLoadingMore != newValue else { return }
            isLoadingMore = true
            Task.detached {
                await onLoadMore()
            }
        })
    }
}
