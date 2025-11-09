//
//  BubbleCorner.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import SwiftUI
import UIKit

public enum BubbleCorner: Int, Hashable, Sendable, Codable, Identifiable {
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
			true
		default:
			false
		}
	}

	var topLeadingRadius: Bool {
		switch self {
		case .all, .receivingTop, .sendingTop, .sendingBottom, .sendingCenter:
			true
		default:
			false
		}
	}

	var topTrailingRadius: Bool {
		switch self {
		case .all, .sendingTop, .receivingTop, .receivingBottom, .receivingCenter:
			true
		default:
			false
		}
	}

	var bottomLeadingRadius: Bool {
		switch self {
		case .all, .receivingBottom, .sendingTop, .sendingBottom, .sendingCenter:
			true
		default:
			false
		}
	}

	var bottomTrailingRadius: Bool {
		switch self {
		case .all, .sendingBottom, .receivingTop, .receivingBottom, .receivingCenter:
			true
		default:
			false
		}
	}

	public func roundedRectange(cornerRadius: CGFloat) -> UnevenRoundedRectangle {
		UnevenRoundedRectangle(
			topLeadingRadius: topLeadingRadius ? cornerRadius : 0,
			bottomLeadingRadius: bottomLeadingRadius ? cornerRadius : 0,
			bottomTrailingRadius: bottomTrailingRadius ? cornerRadius : 0,
			topTrailingRadius: topTrailingRadius ? cornerRadius : 0,
			style: .continuous
		)
	}
}

extension BubbleCorner {
	public var uiRectCorner: UIRectCorner {
		switch self {
		case .all:
			.allCorners
		case .receivingTop:
			[.topLeft, .topRight, .bottomRight]
		case .receivingCenter:
			[.topRight, .bottomRight]
		case .receivingBottom:
			[.topRight, .bottomRight, .bottomLeft]
		case .sendingTop:
			[.topLeft, .topRight, .bottomLeft]
		case .sendingCenter:
			[.topLeft, .bottomLeft]
		case .sendingBottom:
			[.topLeft, .bottomLeft, .bottomRight]
		case .none:
			[]
		}
	}
}
