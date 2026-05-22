//
//  BubbleCorner.swift
//  Database
//
//  Created by Aung Ko Min on 20/5/26.
//

import Foundation
import SwiftUI

public enum BubbleCorner: Int, Hashable, Sendable, Codable, Identifiable {
    case all
    case receivingTop
    case receivingCenter
    case receivingBottom
    case sendingTop
    case sendingCenter
    case sendingBottom
    case none

    // MARK: Public

    public var id: Int {
        rawValue
    }

    public var isCenter: Bool {
        switch self {
        case .receivingCenter,
            .sendingCenter:
            true
        default:
            false
        }
    }

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

    @MainActor
    public func roundedRectange(cornerRadius: CGFloat) -> UnevenRoundedRectangle
    {
        UnevenRoundedRectangle(
            topLeadingRadius: topLeadingRadius ? cornerRadius : 0,
            bottomLeadingRadius: bottomLeadingRadius ? cornerRadius : 0,
            bottomTrailingRadius: bottomTrailingRadius ? cornerRadius : 0,
            topTrailingRadius: topTrailingRadius ? cornerRadius : 0,
            style: .continuous
        )
    }

    var topLeadingRadius: Bool {
        switch self {
        case .all,
            .receivingTop,
            .sendingBottom,
            .sendingCenter,
            .sendingTop:
            true
        default:
            false
        }
    }

    var topTrailingRadius: Bool {
        switch self {
        case .all,
            .receivingBottom,
            .receivingCenter,
            .receivingTop,
            .sendingTop:
            true
        default:
            false
        }
    }

    var bottomLeadingRadius: Bool {
        switch self {
        case .all,
            .receivingBottom,
            .sendingBottom,
            .sendingCenter,
            .sendingTop:
            true
        default:
            false
        }
    }

    var bottomTrailingRadius: Bool {
        switch self {
        case .all,
            .receivingBottom,
            .receivingCenter,
            .receivingTop,
            .sendingBottom:
            true
        default:
            false
        }
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
