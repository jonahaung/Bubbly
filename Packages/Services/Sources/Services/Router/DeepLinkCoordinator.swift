//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Foundation
import XUI

public struct DeepLinkCoordinator: Sendable {

    private let codec: DeeplinkCodec
    private let planner: DeeplinkActionPlanner
    private let sideEffects: SideEffectHandler

	@MainActor
    public init(
		codec: DeeplinkCodec = .standard,
		planner: DeeplinkActionPlanner = .default(),
		sideEffects: SideEffectHandler = .default
    ) {
        self.codec = codec
        self.planner = planner
        self.sideEffects = sideEffects
    }

    public func onOpenURL(url: URL) async {
        switch codec.parse(url) {
        case let .success(link):
            await handle(link: link)
        case let .failure(error):
            log(error)
        }
    }

    public func actions(link: Deeplink) -> [DeeplinkAction] {
        planner.plan(link)
    }

    public func handle(link: Deeplink) async {
        let actions = planner.plan(link)

        do {
            try await AsyncOrderedStream.mapOrdered(inputs: actions, transform: handleDeepLinkAction)
        } catch {
            log(error)
        }
    }

    /// Expose a small URL builder so UI can generate app links without touching codec directly.
    public func url(for link: Deeplink, style: DeeplinkCodec.URLStyle = .customScheme()) -> URL? {
        codec.url(for: link, style: style)
    }
}

private extension DeepLinkCoordinator {
    @concurrent
    func handleDeepLinkAction(_ action: DeeplinkAction) async throws {
		let router = await Router.shared
        switch action {
        case let .selectTab(tab):
            await router.selectTab(tab)
        case let .pushToNav(path):
            await router.pushToNav(path)
        case let .presentModel(path):
            await router.presentModel(path)
        case let .sideEffect(effect):
            // Run off the main actor but preserve ordering by awaiting
            try await Task.detached { [sideEffects] in
                try await sideEffects.run(effect)
            }.value
        }
    }
}

public extension DeepLinkCoordinator {
//    static let shared: DeepLinkCoordinator = .init(
//        router: Router.shared,
//        codec: DeeplinkCodec(
//            config: .init(
//                scheme: AppInformation.urlScheme,
//                supportedVersions: Set(["v1"]),
//                queryValidation: .strict
//            ),
//            aliases: .init(routeAliases: ["conv": "conversation"]),
//            telemetry: .default
//        ),
//        planner: .default(tabMapping: .default, navMapping: .default),
//        sideEffects: .default
//    )
}
