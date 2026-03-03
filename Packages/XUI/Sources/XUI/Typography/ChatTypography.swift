//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

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
    static let `default` = Typography(
        body: .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize),
        callout: .system(size: UIFont.preferredFont(forTextStyle: .callout).pointSize),
        subHeadline: .system(size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize),
        headLine:
        .system(
            size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        ),
        footnote:
        .system(
            size: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
            design: .rounded
        ),
        caption1:
        .system(
            size: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            design: .rounded
        ),
        caption2:
        .system(
            size: UIFont.preferredFont(forTextStyle: .caption2).pointSize,
            design: .rounded
        )
    )
}

public extension EnvironmentValues {
    @Entry var typography = Typography.default
}
