//  MsgsScrollViewLayout+Models.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  MsgsScrollViewLayout+Models.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/4/26.
//
import Foundation
import SwiftUI

extension MsgsScrollViewLayout {

    struct Cache: Sendable, Hashable, Equatable {
        struct CellLayout: Sendable, Hashable {
            let id: String
            let size: CGSize
            let position: CGPoint
            let anchor: UnitPoint
        }

        let totalHeight: CGFloat
        let layouts: [CellLayout]
        let signatureHash: Int
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.totalHeight == rhs.totalHeight && lhs.layouts == rhs.layouts
        }
    }

    struct SizeKey: Sendable, Hashable {
        let uid: String
        let width: Int
        let selected: Bool
        let headerID: Int
    }
    
}
