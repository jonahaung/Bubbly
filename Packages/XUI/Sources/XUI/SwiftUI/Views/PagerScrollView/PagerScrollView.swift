//
//  PageTabView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 26/4/23.
//

import SwiftUI
import Combine

@available(iOS 18.0, *)
public struct PagerScrollView<Page, Content>: View
where Page: Sendable & Equatable & Hashable & Identifiable, Content: View {

    private let items: [Page]
    private let content: (Page) -> Content
    @Binding private  var selection: Page
    @State private var position: ScrollPosition = .init()
    private var targetPublisher = PassthroughSubject<Page, Never>()

    public init(items: [Page], selection: Binding<Page>, content: @escaping (Page) -> Content) {
        self.items = items
        self.content = content
        self._selection = selection
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .containerRelativeFrame([.horizontal])
                            .equatable(by: item)
                            .id(item)
                    }
                }.scrollTargetLayout()
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
            .scrollPosition($position)
            .overlay(alignment: .bottom) {
                if items.count > 1 {
                    XPhotoPageControl(selection: .constant(items.firstIndex(of: selection) ?? 0), length: items.count, size: 12)
                        .foregroundStyle(Color.white.gradient)
                        .padding(.bottom, 3)
                }
            }
            .onScrollPhaseChange { _, newPhase, context in
                guard newPhase == .idle else { return }
                let count = items.count.cgFloat
                let scrollView = context.geometry
                guard scrollView.contentSize.width > geometry.size.width else { return }
                let totalWidth = scrollView.contentSize.width - (scrollView.contentInsets.leading + scrollView.contentInsets.trailing)
                let value = ((scrollView.contentOffset.x+scrollView.bounds.width/2) * count/totalWidth).int
                if let target = items[safe: value], selection != target {
                    selection = target
                }
            }
            .onChange(of: selection) { oldValue, newValue in
                guard oldValue != newValue else { return }
                if position.viewID == nil || position.viewID as? Page != newValue {
                    withAnimation(.spring) {
                        position.scrollTo(id: newValue)
                    }
                }
            }
            .onReceive(targetPublisher.removeDuplicates().debounce(for: 0.5, scheduler: RunLoop.main)) { output in
                if output != selection {
                    selection = output
                }
            }
            .onAppear {
                position.scrollTo(id: selection)
            }
        }
    }
}
