//
//  ToastStyle.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import Foundation
import SwiftUI

public enum ToastStyle: Sendable, Hashable, CaseIterable {
	case `default`, top, bottom

	var alignment: Alignment {
		switch self {
		case .default:
			.top
		case .top:
			.top
		case .bottom:
			.bottom
		}
	}

	var edge: Edge {
		if alignment == .top {
			return .top
		}
		return .bottom
	}
}
