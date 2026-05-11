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

    struct Cache: Sendable, Hashable {
        struct CellLayout: Sendable, Hashable {
            let id: String
            let size: CGSize
            let position: CGPoint
            let anchor: UnitPoint
        }

        let totalHeight: CGFloat
        let layouts: [CellLayout]
        let signatureHash: Int
    }

    struct SizeKey: Sendable, Hashable {
        let uid: String
        let width: Int
        let selected: Bool
        let headerID: Int
    }
}
