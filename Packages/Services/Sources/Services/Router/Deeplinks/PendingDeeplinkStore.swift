// © 2026 Aung Ko Min

import Foundation
import Core

public actor PendingDeeplinkStore {
    public static let shared = PendingDeeplinkStore()

    private let storage: GroupStorage
    private let codec: DeeplinkCodec
    private var links = [Deeplink]()
    private var isMainRouteReady = false

    private init(
        storage: GroupStorage = .shared,
        codec: DeeplinkCodec = .standard
    ) {
        self.storage = storage
        self.codec = codec
        self.links = Self.loadPersistedLinks(storage: storage, codec: codec)
    }

    public func enqueue(_ link: Deeplink) {
        guard !links.contains(link) else {
            return
        }
        links.append(link)
        persistLinks()
    }

    public func setMainRouteReady(_ isReady: Bool) {
        isMainRouteReady = isReady
    }

    public func drainIfReady() async {
        guard isMainRouteReady, !links.isEmpty else {
            return
        }

        let pending = links
        links.removeAll()
        persistLinks()

        for link in pending {
            await DeepLinkCoordinator().handle(link: link, router: .shared)
        }
    }

    private func persistLinks() {
        let values = links.compactMap { codec.url(for: $0)?.absoluteString }
        if values.isEmpty {
            storage.delete(for: .router(.targetedDeepLinkPath))
        } else {
            storage.save(values, for: .router(.targetedDeepLinkPath))
        }
    }

    private static func loadPersistedLinks(
        storage: GroupStorage,
        codec: DeeplinkCodec
    ) -> [Deeplink] {
        guard let values = storage.codable([String].self, for: .router(.targetedDeepLinkPath)) else {
            return []
        }

        return values.compactMap { value in
            guard let url = URL(string: value) else {
                return nil
            }
            switch codec.parse(url) {
            case .success(let link):
                return link
            case .failure:
                return nil
            }
        }
    }
}
