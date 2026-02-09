//
//  AnyMsgData++.swift
//  Services
//
//  Created by Aung Ko Min on 5/2/26.
//

import Database
import Foundation

public extension AnyMsgData {
	@MainActor
	var deeplinkURL: URL? {
		DeepLinkCoordinator.shared.url(for: .conversation(id: conID))
	}
}
