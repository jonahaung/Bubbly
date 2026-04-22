//
//  MsgsScrollViewLayout+Models.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/4/26.
//
import Foundation

extension MsgsScrollViewLayout {

    struct Cache: Hashable {
        struct CellLayout: Hashable {
            let id: String
            let size: CGSize
            let position: CGPoint
        }

        let totalHeight: CGFloat
        let layouts: [CellLayout]
        let signatureHash: Int
    }
    struct SizeKey: Hashable {
        let uid: String
        let width: CGFloat
        let selected: Bool
    }
}
