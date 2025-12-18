//
//  ScrollViewPrefetcher.swift
//  XUI
//
//  Created by Aung Ko Min on 22/9/25.
//

import SwiftUI

@MainActor
public protocol ScrollViewPrefetcherDelegate: AnyObject {
    func allIndices(for prefetcher: ScrollViewPrefetcher) -> Range<Int>
    func prefetcher(_ prefetcher: ScrollViewPrefetcher, prefetchItemsAt indices: [Int])
    func prefetcher(_ prefetcher: ScrollViewPrefetcher, cancelPrefetchingFor indices: [Int])
}

@MainActor
public final class ScrollViewPrefetcher {
    // MARK: - Properties

    private let windowSize: Int
    public weak var delegate: ScrollViewPrefetcherDelegate?

    private var visibleIndices = Set<Int>()
    private var lastVisibleIndices = Set<Int>()

    private var prefetchWindow: Range<Int> = 0 ..< 0
    private var isRefreshScheduled = false

    // MARK: - Init

    public init(windowSize: Int = 12) {
        self.windowSize = windowSize
    }

    // MARK: - Public

    public func onAppear(_ index: Int) {
        visibleIndices.insert(index)
        scheduleRefreshIfNeeded()
    }

    public func onDisappear(_ index: Int) {
        visibleIndices.remove(index)
        scheduleRefreshIfNeeded()
    }

    // MARK: - Internal

    /// SwiftUI sometimes calls `onAppear`/`onDisappear` out of order, so we debounce updates.
    private func scheduleRefreshIfNeeded() {
        guard !isRefreshScheduled else { return }
        isRefreshScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            self?.updatePrefetchWindow()
        }
    }

    private func updatePrefetchWindow() {
        isRefreshScheduled = false
        guard !visibleIndices.isEmpty else { return }

        let newWindow: Range<Int>

        if lastVisibleIndices.isEmpty {
            // First load: prefetch ahead of the initial max
            let start = (visibleIndices.max() ?? 0) + 1
            newWindow = start ..< (start + windowSize)
        } else {
            let scrollingDown = (visibleIndices.max() ?? 0) > (lastVisibleIndices.max() ?? 0)
            if scrollingDown || visibleIndices.contains(0) {
                let start = (visibleIndices.max() ?? 0) + 1
                newWindow = start ..< (start + windowSize)
            } else {
                let end = (visibleIndices.min() ?? 0) - 1
                newWindow = (end - windowSize) ..< end
            }
        }
        applyPrefetchWindow(newWindow)
        lastVisibleIndices = visibleIndices
    }

    private func applyPrefetchWindow(_ newWindow: Range<Int>) {
        let oldSet = Set(prefetchWindow)
        let newSet = Set(newWindow)
        prefetchWindow = newWindow

        guard let delegate else { return }
        let validIndices = Set(delegate.allIndices(for: self))

        let added = newSet.subtracting(oldSet).intersection(validIndices).sorted()
        let removed = oldSet.subtracting(newSet).intersection(validIndices).sorted()

        if !added.isEmpty {
            delegate.prefetcher(self, prefetchItemsAt: added)
        }
        if !removed.isEmpty {
            delegate.prefetcher(self, cancelPrefetchingFor: removed)
        }
    }
}
