//
//  ChatLayoutCache.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/4/26.
//

import CoreGraphics
import Foundation

final class MsgsScrollViewLayoutCache: @unchecked Sendable {

    private let maxSizeEntries: Int
    private let maxLayoutEntries: Int

    // MARK: - Storage

    private var sizeStorage: [String: CGSize] = [:]
    private var sizeOrder: [String] = []  // LRU tracking

    private var layoutStorage: [Int: MsgsScrollViewLayout.Cache] = [:]

    private let lock = NSLock()

    init(
        maxSizeEntries: Int = 2000,
        maxLayoutEntries: Int = 8
    ) {
        self.maxSizeEntries = maxSizeEntries
        self.maxLayoutEntries = maxLayoutEntries
    }

    // MARK: - Size Cache

    func size(for key: String) -> CGSize? {
        lock.lock()
        defer { lock.unlock() }

        guard let value = sizeStorage[key] else { return nil }

        // LRU refresh
        if let index = sizeOrder.firstIndex(of: key) {
            sizeOrder.remove(at: index)
        }
        sizeOrder.append(key)

        return value
    }

    func setSize(_ size: CGSize, for key: String) {
        lock.lock()
        defer { lock.unlock() }

        if sizeStorage[key] == nil {
            sizeOrder.append(key)
        }

        sizeStorage[key] = size
        enforceSizeLimit()
    }

    private func enforceSizeLimit() {
        while sizeOrder.count > maxSizeEntries {
            let oldest = sizeOrder.removeFirst()
            sizeStorage.removeValue(forKey: oldest)
        }
    }

    func removeAllSizes() {
        lock.lock()
        sizeStorage.removeAll()
        sizeOrder.removeAll()
        lock.unlock()
    }

    // MARK: - Layout Cache

    func cache(signature: Int) -> MsgsScrollViewLayout.Cache? {
        lock.lock()
        let value = layoutStorage[signature]
        lock.unlock()

        return value
    }

    func setCache(
        _ cache: MsgsScrollViewLayout.Cache,
        signature: Int
    ) {
        lock.lock()

        if layoutStorage.count >= maxLayoutEntries {
            layoutStorage.remove(at: layoutStorage.startIndex)
        }
        layoutStorage[signature] = cache
        lock.unlock()
    }

    func removeAllLayouts() {
        lock.lock()
        layoutStorage.removeAll()
        lock.unlock()
    }

    // MARK: - Global Invalidation

    func invalidateAll() {
        lock.lock()
        sizeStorage.removeAll()
        sizeOrder.removeAll()
        layoutStorage.removeAll()
        lock.unlock()
    }
}
