// © 2026 Aung Ko Min

import Core
import Foundation
import XUI

public struct DeepLinkCoordinator: Sendable {
    
    private let codec: DeeplinkCodec
    private let planner: DeeplinkActionPlanner
    private let sideEffects: SideEffectHandler

    public init(
        codec: DeeplinkCodec = .standard,
        planner: DeeplinkActionPlanner = .default(),
        sideEffects: SideEffectHandler = .default
    ) {
        self.codec = codec
        self.planner = planner
        self.sideEffects = sideEffects
    }

    public func onOpenURL(url: URL, router: Router) async {
        switch codec.parse(url) {
        case .success(let link):
            await handle(link: link, router: router)
        case .failure(let error):
            log(error)
        }
    }

    public func actions(link: Deeplink) -> [DeeplinkAction] {
        planner.plan(link)
    }

    public func handle(link: Deeplink, router: Router) async {
        let actions = planner.plan(link)

        do {
            try await AsyncOrderedStream.mapOrdered(inputs: actions) { action in
                try await handleDeepLinkAction(action, router: router)
            }
        } catch {
            log(error)
        }
    }
}

extension DeepLinkCoordinator {
    @concurrent
    fileprivate func handleDeepLinkAction(
        _ action: DeeplinkAction,
        router: Router
    ) async throws {
        switch action {
        case .selectTab(let tab):
            await router.selectTab(tab)
        case .pushToNav(let path):
            await router.pushToNav(path)
        case .presentModel(let path):
            await router.presentModel(path)
        case .sideEffect(let effect):
            try await Task.detached { [sideEffects] in
                try await sideEffects.run(effect)
            }
            .value
        }
    }
}
