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
    
    public func contains(_ edge: Edge) -> Bool {
        switch edge {
        case .top:
            topLeading && topTrailing
        case .bottom:
            bottomLeading && bottomTrailing
        case .leading:
            topLeading && bottomLeading
        case .trailing:
            topTrailing && bottomTrailing
        }
    }

    @MainActor
    public func roundedRectange(cornerRadius: CGFloat) -> UnevenRoundedRectangle
    {
        UnevenRoundedRectangle(
            topLeadingRadius: topLeading ? cornerRadius : 0,
            bottomLeadingRadius: bottomLeading ? cornerRadius : 0,
            bottomTrailingRadius: bottomTrailing ? cornerRadius : 0,
            topTrailingRadius: topTrailing ? cornerRadius : 0,
            style: .continuous
        )
    }

    public var topLeading: Bool {
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

    public var topTrailing: Bool {
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

    public var bottomLeading: Bool {
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

    public var bottomTrailing: Bool {
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
