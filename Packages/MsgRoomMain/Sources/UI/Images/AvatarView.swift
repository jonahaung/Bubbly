//
//  ContactAvatarView.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 7/4/24.
//

import Foundation

public enum AvatarSize {
	case mini
	case small
	case medium
	case original
	case custom(CGFloat)

	var value: CGFloat? {
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
