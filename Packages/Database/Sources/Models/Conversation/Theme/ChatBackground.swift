//
//  ChatBackground.swift
//  Models
//
//  Created by Aung Ko Min on 28/2/25.
//

import SwiftUI
import XUI

public enum ChatBackground: Int, Codable, CaseIterable, Sendable {
	case `default`, system, group
}

extension ChatBackground: Identifiable {
	public var id: Int {
		rawValue
	}

	public var color: Color {
		switch self {
		case .default:
			.secondarySystemBackground
		case .group:
			.systemGroupedBackground
		case .system:
			.systemBackground
		}
	}
}

extension ChatBackground: XPickable, EmptyRepresentable {
	public var title: String {
		String(describing: self)
	}

	public static var empty: Database.ChatBackground {
		.default
	}
}
