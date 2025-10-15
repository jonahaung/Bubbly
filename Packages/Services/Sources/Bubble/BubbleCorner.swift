//
//  BubbleCorner.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import UIKit
import SwiftUI

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
