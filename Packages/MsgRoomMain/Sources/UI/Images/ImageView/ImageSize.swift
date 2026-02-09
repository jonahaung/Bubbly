//
//  ImageSize.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Foundation

public enum ImageSize: Sendable, Equatable, Codable {
	case mini
	case small
	case medium
	case large
	case original
	case custom(CGFloat)

	public var value: CGFloat? {
		switch self {
		case .mini:
			35
		case .small:
			50
		case .medium:
			100
		case .large:
			300
		case .original:
			nil
		case let .custom(cGFloat):
			cGFloat
		}
	}

	public var width: CGFloat? {
		value
	}

	public var height: CGFloat? {
		value
	}
}
