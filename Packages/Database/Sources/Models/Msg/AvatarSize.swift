//
//  AvatarSize.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Foundation

public enum AvatarSize: ImageSize {
	public var width: CGFloat? { value }
	public var height: CGFloat? { value }

	case mini
	case small
	case medium
	case original
	case custom(CGFloat)

	public var value: CGFloat? {
		switch self {
		case .mini:
			return 30
		case .small:
			return 50
		case .medium:
			return 100
		case .original:
			return nil
		case .custom(let cGFloat):
			return cGFloat
		}
	}
}
