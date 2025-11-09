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
			30
		case .small:
			50
		case .medium:
			100
		case .original:
			nil
		case .custom(let cGFloat):
			cGFloat
		}
	}
}
