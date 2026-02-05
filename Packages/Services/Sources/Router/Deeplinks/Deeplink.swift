//
//  Deeplink.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public enum Deeplink: Hashable, Sendable {
	case home
	case profile(id: String)
	case conversation(id: String)
	case settings
}
