//
//  GitHubMarkdownStyle.swift
//  XUI
//
//  Created by Aung Ko Min on 10/4/26.
//

import Foundation
import SwiftUI

public struct GitHubMarkdownStyle {
    
    public init() {}

    // MARK: Public
    public var base: AttributeContainer = .paragraph

    public func block(
        _ kind: PresentationIntent.Kind,
    ) -> AttributeContainer {
        switch kind {
        case let .header(level):
            let size = UIFont.preferredFont(forTextStyle: .title2).pointSize - CGFloat(level * 2)
            let font = Font.system(
                size: size,
                weight: .semibold,
                design: .rounded,
            )
            return .init()
                .font(font)
                .foregroundColor(Color.primaryText)
                .lineHeight(.multiple(factor: 1.3))
                .paragraphStyle(.default)
        case .listItem,
             .orderedList,
             .unorderedList:
            return .init()
                .font(.system(size: labelFontSize))
                .foregroundColor(Color.secondaryText)
                .lineHeight(.multiple(factor: 1.4))
                .paragraphStyle(.default)
        case .codeBlock:
            return .init()
                .font(
                    .system(size: systemFontSize, weight: .medium, design: .monospaced)
                        .width(.compressed),
                )
                .foregroundColor(.secondaryText)
        case .blockQuote:
            return .init()
                .font(.system(size: systemFontSize + 2, weight: .thin, design: .serif))
                .foregroundColor(.secondaryText)
                .paragraphStyle(.default)
        case .paragraph:
            return .paragraph
                .foregroundColor(Color.appPrimary)
        case .thematicBreak:
            return .init()
                .lineHeight(.multiple(factor: 1))
                .foregroundColor(.tertiaryText)
        default:
            return .paragraph
        }
    }

    
    private var labelFontSize: CGFloat {
        UIFont.labelFontSize
    }

    private var systemFontSize: CGFloat {
        UIFont.systemFontSize
    }
}

import UIKit

extension NSParagraphStyle: @unchecked @retroactive Sendable {
    static let `default`: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineBreakStrategy = .standard
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineHeightMultiple = 1.3
        return paragraphStyle
    }()
}

public extension AttributeContainer {
    static let paragraph: AttributeContainer = {
        var container = AttributeContainer()
        container.font = .system(size: UIFont.labelFontSize)
        container.lineHeight = .multiple(factor: 1.3)
        container.paragraphStyle = .default
        return container
    }()
}
