//
//  BubbleCorner.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import UIKit
import SwiftUI

public enum BubbleCorner: Int, Hashable, Sendable, Codable, Identifiable {
	public static let allShape = BubbleCorner.all.roundedRectange(cornerRadius: 17)
	public static let receivingTopShape = BubbleCorner.receivingTop.roundedRectange(cornerRadius: 17)
	public static let receivingCenterShape = BubbleCorner.receivingCenter.roundedRectange(cornerRadius: 17)
	public static let receivingBottomShape = BubbleCorner.receivingBottom.roundedRectange(cornerRadius: 17)
	public static let sendingTopShape = BubbleCorner.sendingTop.roundedRectange(cornerRadius: 17)
	public static let sendingCenterShape = BubbleCorner.sendingCenter.roundedRectange(cornerRadius: 17)
	public static let sendingBottomShape = BubbleCorner.sendingBottom.roundedRectange(cornerRadius: 17)
	public static let noneShape = BubbleCorner.none.roundedRectange(cornerRadius: 17)

	public var id: Int { rawValue }
	case all, receivingTop, receivingCenter, receivingBottom, sendingTop, sendingCenter, sendingBottom, none

	public mutating func append(_ edge: VerticalEdge) {
		switch self {
		case .all:
			break
		case .receivingTop:
			switch edge {
			case .top:
				break
			case .bottom:
				self = .all
			}
		case .receivingCenter:
			switch edge {
			case .top:
				self = .receivingTop
			case .bottom:
				self = .receivingBottom
			}
		case .receivingBottom:
			switch edge {
			case .top:
				self = .all
			case .bottom:
				break
			}
		case .sendingTop:
			switch edge {
			case .top:
				break
			case .bottom:
				self = .all
			}
		case .sendingCenter:
			switch edge {
			case .top:
				self = .sendingTop
			case .bottom:
				self = .sendingBottom
			}
		case .sendingBottom:
			switch edge {
			case .top:
				self = .all
			case .bottom:
				break
			}
		case .none:
			break
		}
	}
	public var isCenter: Bool {
		switch self {
		case .receivingCenter, .sendingCenter:
			return true
		default:
			return false
		}
	}
	var topLeadingRadius: Bool {
		switch self {
		case .all, .receivingTop, .sendingTop, .sendingBottom, .sendingCenter:
			return true
		default:
			return false
		}
	}
	var topTrailingRadius: Bool {
		switch self {
		case .all, .sendingTop, .receivingTop, .receivingBottom, .receivingCenter:
			return true
		default:
			return false
		}
	}
	var bottomLeadingRadius: Bool {
		switch self {
		case .all, .receivingBottom, .sendingTop, .sendingBottom, .sendingCenter:
			return true
		default:
			return false
		}
	}
	var bottomTrailingRadius: Bool {
		switch self {
		case .all, .sendingBottom, .receivingTop, .receivingBottom, .receivingCenter:
			return true
		default:
			return false
		}
	}


	public func roundedRectange(cornerRadius: CGFloat) -> UnevenRoundedRectangle {
		UnevenRoundedRectangle(
			topLeadingRadius: topLeadingRadius ? cornerRadius: 0,
			bottomLeadingRadius: bottomLeadingRadius ? cornerRadius : 0,
			bottomTrailingRadius: bottomTrailingRadius ? cornerRadius: 0,
			topTrailingRadius: topTrailingRadius ? cornerRadius : 0,
			style: .continuous
		)
	}

	public var shape: UnevenRoundedRectangle {
		switch self {
		case .all:
			Self.allShape
		case .receivingTop:
			Self.receivingTopShape
		case .receivingCenter:
			Self.receivingCenterShape
		case .receivingBottom:
			Self.receivingBottomShape
		case .sendingTop:
			Self.sendingTopShape
		case .sendingCenter:
			Self.sendingCenterShape
		case .sendingBottom:
			Self.sendingBottomShape
		case .none:
			Self.noneShape
		}
	}

//	topLeadingRadius: corn, bottomLeadingRadius: , bottomTrailingRadius: , topTrailingRadius: ,
}

public extension BubbleCorner {
	var uiRectCorner: UIRectCorner {
		switch self {
		case .all:
			return .allCorners
		case .receivingTop:
			return [.topLeft, .topRight, .bottomRight]
		case .receivingCenter:
			return [.topRight, .bottomRight]
		case .receivingBottom:
			return [.topRight, .bottomRight, .bottomLeft]
		case .sendingTop:
			return [.topLeft, .topRight, .bottomLeft]
		case .sendingCenter:
			return [.topLeft, .bottomLeft]
		case .sendingBottom:
			return [.topLeft, .bottomLeft, .bottomRight]
		case .none:
			return []
		}
	}
}
