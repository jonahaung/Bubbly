// © 2026 Aung Ko Min

import Foundation

public actor PendingDeeplinkStore {
    public static let shared = PendingDeeplinkStore()

    private var links = [Deeplink]()
    private var isMainRouteReady = false

    private init() {}

    public func enqueue(_ link: Deeplink) {
        links.append(link)
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

        for link in pending {
            await DeepLinkCoordinator().handle(link: link, router: .shared)
        }
    }
}
