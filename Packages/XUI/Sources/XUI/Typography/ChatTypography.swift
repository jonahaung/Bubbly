//
//  ChatTypography.swift
//  XUI
//
//  Created by Aung Ko Min on 15/12/25.
//

import SwiftUI
import UIKit

public struct Typography: Sendable {
	public let message: Font
	public let sender: Font
	public let timestamp: Font

	public init(
		message: Font,
		sender: Font,
		timestamp: Font
	) {
		self.message = message
		self.sender = sender
		self.timestamp = timestamp
	}
}
public extension Typography {

	static let `default` = Typography(
		message: .chatScaled(
			baseSize: 16.5,
			weight: .regular,
			textStyle: .body
		),

		sender: .chatScaled(
			baseSize: 13,
			weight: .medium,
			textStyle: .subheadline
		),

		timestamp: .chatScaled(
			baseSize: 12,
			weight: .regular,
			textStyle: .caption1
		)
	)
}
public extension Font {

	static func chatScaled(
		baseSize: CGFloat,
		weight: Font.Weight,
		textStyle: UIFont.TextStyle
	) -> Font {
		let metrics = UIFontMetrics(forTextStyle: textStyle)

		let scaledSize = metrics.scaledValue(
			for: baseSize,
			compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
		)

		return .system(
			size: scaledSize,
			weight: weight
		)
	}
}
private struct TypographyKey: EnvironmentKey {
	static let defaultValue: Typography = .default
}

public extension EnvironmentValues {
	var typography: Typography {
		get { self[TypographyKey.self] }
		set { self[TypographyKey.self] = newValue }
	}
}
public extension Font {
	static var chat: ChatFontProxy {
		ChatFontProxy()
	}
}

public struct ChatFontProxy {
	@Environment(\.typography) private var typography

	public var message: Font { typography.message }
	public var sender: Font { typography.sender }
	public var timestamp: Font { typography.timestamp }
}
