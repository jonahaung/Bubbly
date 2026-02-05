//
//  DeepLinkCoordinator.swift
//  Services
//
//  Created by Aung Ko Min on 30/1/26.
//

import Foundation
import Core
import XUI

@MainActor
public final class DeepLinkCoordinator {

	private let codec: DeeplinkCodec
	private let planner: DeeplinkActionPlanner
	private let sideEffects: SideEffectHandler

	private unowned let router: Router

	public init(
		router: Router,
		codec: DeeplinkCodec,
		planner: DeeplinkActionPlanner,
		sideEffects: SideEffectHandler
	) {
        self.router = router
        self.codec = codec
        self.planner = planner
        self.sideEffects = sideEffects
	}

	public func onOpenURL(url: URL) {
		switch codec.parse(url) {
		case .success(let link):
			handle(link: link)
		case .failure(let error):
			log(error)
		}
	}

	public func handle(link: Deeplink) {
		let actions = planner.plan(link)
		Task { [weak self] in
			guard let self else { return }
			do {
				try await AsyncOrderedStream.mapOrdered(inputs: actions) { action in
					try await self.handleDeepLinkAction(action)
				}
			} catch {
				log(error)
			}
		}
	}

	// Expose a small URL builder so UI can generate app links without touching codec directly.
	public func url(for link: Deeplink, style: DeeplinkCodec.URLStyle = .customScheme()) -> URL? {
		codec.url(for: link, style: style)
	}
}

private extension DeepLinkCoordinator {
	@concurrent
	func handleDeepLinkAction(_ action: DeeplinkAction) async throws {
		switch action {
		case .selectTab(let tab):
			await router.selectTab(tab)
		case .pushToNav(let path):
			await router.pushToNav(path)

		case .presnetModel(let path):
			await router.presnetModel(path)
		case .sideEffect(let effect):
			// Run off the main actor but preserve ordering by awaiting
			try await Task.detached { [sideEffects] in
				try await sideEffects.run(effect)
			}.value
		}
	}
}

public extension DeepLinkCoordinator {
	static let shared: DeepLinkCoordinator = {
		let codec = DeeplinkCodec(
			config: .init(
				scheme: AppInformation.urlScheme,
				supportedVersions: Set(["v1"]),
				queryValidation: .strict
			),
			aliases: .init(routeAliases: ["conv": "conversation"]),
			telemetry: .default
		 )
		let planner = DeeplinkActionPlanner.default(tabMapping: .default, navMapping: .default)

		return DeepLinkCoordinator(
			router: Router.shared,
			codec: codec,
			planner: planner,
			sideEffects: .default
		)
	}()
}

