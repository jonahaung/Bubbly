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
        body: .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize).leading(.loose),
        callout: .system(size: UIFont.preferredFont(forTextStyle: .callout).pointSize).leading(.tight),
        subHeadline: .system(size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize),
        headLine: .system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize),
        footnote: .system(size: UIFont.preferredFont(forTextStyle: .footnote).pointSize).leading(.tight),
        caption1: .system(size: UIFont.preferredFont(forTextStyle: .caption1).pointSize).leading(.tight),
        caption2: .system(size: UIFont.preferredFont(forTextStyle: .caption2).pointSize).leading(.tight)
    )
}
public extension Typography {

    static let helvetica: Typography = .init(
        body:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .body).pointSize
            )
            .leading(.loose),
        callout:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .callout).pointSize
            ),
        subHeadline:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize
            ),
        headLine:
            .custom(
                "HelveticaNeue-Bold",
                size: UIFont.preferredFont(forTextStyle: .headline).pointSize
            ),
        footnote:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .footnote).pointSize
            )
            .leading(.tight),
        caption1:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .caption1).pointSize
            ),
        caption2:
            .custom(
                "HelveticaNeue",
                size: UIFont.preferredFont(forTextStyle: .caption2).pointSize
            )
    )
}
public extension EnvironmentValues {
    @Entry var typography: Typography = .helvetica
}
