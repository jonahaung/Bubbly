//  ChatTypography.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import UIKit
import SwiftUI

public struct Typography: Sendable {
    public let body: Font
    public let callout: Font
    public let subHeadline: Font
    public let headLine: Font
    public let footnote: Font
    public let caption1: Font
    public let caption2: Font

    public init(
        body: Font,
        callout: Font,
        subHeadline: Font,
        headLine: Font,
        footnote: Font,
        caption1: Font,
        caption2: Font
    ) {
        self.body = body
        self.callout = callout
        self.subHeadline = subHeadline
        self.headLine = headLine
        self.footnote = footnote
        self.caption1 = caption1
        self.caption2 = caption2
    }
}

public extension Typography {
    static let system: Typography = .init(
        body: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .body).pointSize, relativeTo: .body),
        callout: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .callout).pointSize, relativeTo: .callout),
        subHeadline: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, relativeTo: .subheadline),
        headLine: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize, relativeTo: .headline),
        footnote: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .footnote).pointSize, relativeTo: .footnote),
        caption1: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize, relativeTo: .caption),
        caption2: .custom(UIFont.systemFontFamilyName, size: UIFont.preferredFont(forTextStyle: .caption2).pointSize, relativeTo: .caption2)
    )
}
public extension Typography {

    static let helvetica: Typography = .init(
        body:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .body).pointSize
            )
            .leading(.loose),
        callout:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .callout).pointSize
            ),
        subHeadline:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize
            ),
        headLine:
            .custom(
                "Helvetica-Bold",
                size: UIFont.preferredFont(forTextStyle: .headline).pointSize
            ),
        footnote:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .footnote).pointSize
            )
            .leading(.tight),
        caption1:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .caption1).pointSize
            ),
        caption2:
            .custom(
                "Helvetica",
                size: UIFont.preferredFont(forTextStyle: .caption2).pointSize
            )
    )
}
public extension EnvironmentValues {
    @Entry var typography: Typography = .system
}
