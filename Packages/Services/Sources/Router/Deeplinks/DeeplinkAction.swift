//
//  DeeplinkAction.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public enum DeeplinkAction: Sendable, Equatable {
	case selectTab(TabPath)
	case pushToNav(NavPath)
	case presnetModel(NavPath)
	case sideEffect(SideEffect)

	public enum SideEffect: Sendable, Equatable, Hashable {
		case prepareForConversation(id: String)
		case prepareForContactDetails(id: String)
		case track(event: String, properties: [String: String])
		case requireAuth(reason: String?)
	}
}
