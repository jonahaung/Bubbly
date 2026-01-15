//
//  ChatTypography.swift
//  XUI
//
//  Created by Aung Ko Min on 15/12/25.
//

import SwiftUI
import UIKit

public struct Typography: Sendable {
	public let body: Font
	public let callout: Font
	public let subHeadline: Font
	public let headLine: Font
	public let footnote: Font

	public init(
		body: Font,
		callout: Font,
		subHeadline: Font,
		headLine: Font,
		footnote: Font
	) {
		self.body = body
		self.callout = callout
		self.subHeadline = subHeadline
		self.headLine = headLine
		self.footnote = footnote
	}
}
public extension Typography {

	static let `default` = Typography(
		body: .chatScaled(
			baseSize: 17,
			weight: .regular,
			textStyle: .body
		),
		callout: .chatScaled(
			baseSize: 14,
			weight: .regular,
			textStyle: .callout
		),
		subHeadline: .chatScaled(
			baseSize: 13,
			weight: .medium,
			textStyle: .footnote
		),

		headLine: .chatScaled(
			baseSize: 17,
			weight: .semibold,
			textStyle: .headline
		),
		footnote: .chatScaled(
			baseSize: 12,
			weight: .medium,
			textStyle: .footnote
		).leading(.tight)
	)
}
public extension Font {

	static func chatScaled(
		baseSize: CGFloat,
		weight: Font.Weight,
		textStyle: UIFont.TextStyle
	) -> Font {
		let metrics = UIFontMetrics(forTextStyle: textStyle)
		let scaledSize = metrics.scaledValue(for: baseSize)

		return .system(
			size: scaledSize,
			weight: weight,
			design: .default
		)
		.leading(.tight)
	}
}

public extension EnvironmentValues {
	@Entry var typography = Typography.default
}
