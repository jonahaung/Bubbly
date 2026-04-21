//
//  MsgsScrollViewLayoutCache.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/4/26.
//

import CoreGraphics
import Foundation

final class MsgsScrollViewLayoutCache: @unchecked Sendable {

    // MARK: - Snapshot (Immutable for readers)

    struct Snapshot {
        var sizeStorage: [String: CGSize]
        var sizeOrder: [String]

        var layoutStorage: [Int: MsgsScrollViewLayout.Cache]
        var layoutOrder: [Int]
    }

    // MARK: - Config

    private let maxSizeEntries: Int
    private let maxLayoutEntries: Int

    // MARK: - Storage

    private let writeLock = NSLock()
    private var snapshot: Snapshot

    // MARK: - Init

    init(
        maxSizeEntries: Int = 1200,
        maxLayoutEntries: Int = 8
    ) {
        self.maxSizeEntries = maxSizeEntries
        self.maxLayoutEntries = maxLayoutEntries

        snapshot = .init(
            sizeStorage: [:],
            sizeOrder: [],
            layoutStorage: [:],
            layoutOrder: []
        )
    }

    // MARK: - Lock-free Reads

    @inline(__always)
    func size(for key: String) -> CGSize? {
        snapshot.sizeStorage[key]
    }

    @inline(__always)
    func cache(signature: Int) -> MsgsScrollViewLayout.Cache? {
        snapshot.layoutStorage[signature]
    }

    // MARK: - Writes (Copy-on-Write + Atomic Swap)

    func setSize(_ size: CGSize, for key: String) {
        writeLock.lock()
        defer { writeLock.unlock() }

        var new = snapshot

        if new.sizeStorage.updateValue(size, forKey: key) == nil {
            new.sizeOrder.append(key)
        } else {
            refresh(&new.sizeOrder, key)
        }

        enforceSizeLimit(&new)

        snapshot = new
    }

    func setCache(
        _ cache: MsgsScrollViewLayout.Cache,
        signature: Int
    ) {
        writeLock.lock()
        defer { writeLock.unlock() }

        var new = snapshot

        if new.layoutStorage.updateValue(cache, forKey: signature) == nil {
            new.layoutOrder.append(signature)
        } else {
            refresh(&new.layoutOrder, signature)
        }

        enforceLayoutLimit(&new)

        snapshot = new
    }

    // MARK: - Partial Invalidation (important for chat)

    func invalidateSizes(for keys: [String]) {
        writeLock.lock()
        defer { writeLock.unlock() }

        var new = snapshot

        for key in keys {
            new.sizeStorage.removeValue(forKey: key)
        }

        new.sizeOrder.removeAll { !new.sizeStorage.keys.contains($0) }

        snapshot = new
    }

    func invalidateLayouts(for signatures: [Int]) {
        writeLock.lock()
        defer { writeLock.unlock() }

        var new = snapshot

        for sig in signatures {
            new.layoutStorage.removeValue(forKey: sig)
        }

        new.layoutOrder.removeAll { !new.layoutStorage.keys.contains($0) }

        snapshot = new
    }

    // MARK: - Full Reset

    func invalidateAll() {
        writeLock.lock()
        snapshot = .init(
            sizeStorage: [:],
            sizeOrder: [],
            layoutStorage: [:],
            layoutOrder: []
        )
        writeLock.unlock()
    }

    // MARK: - LRU Helpers

    @inline(__always)
    private func refresh<T: Equatable>(_ order: inout [T], _ key: T) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.append(key)
    }

    private func enforceSizeLimit(_ snap: inout Snapshot) {
        while snap.sizeOrder.count > maxSizeEntries {
            let oldest = snap.sizeOrder.removeFirst()
            snap.sizeStorage.removeValue(forKey: oldest)
        }
    }

    private func enforceLayoutLimit(_ snap: inout Snapshot) {
        while snap.layoutOrder.count > maxLayoutEntries {
            let oldest = snap.layoutOrder.removeFirst()
            snap.layoutStorage.removeValue(forKey: oldest)
        }
    }
}
