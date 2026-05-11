//  MsgsScrollViewLayoutCache.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  MsgsScrollViewLayoutCache.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/4/26.
//
import Foundation
import CoreGraphics

nonisolated
final class MsgsScrollViewLayoutCache {
    
    var sizeStorage: [MsgsScrollViewLayout.SizeKey: CGSize] = [:]
    var layoutStorage: [Int: MsgsScrollViewLayout.Cache] = [:]
    
    init() {}

    @inline(__always) func size(for key: MsgsScrollViewLayout.SizeKey) -> CGSize? {
        sizeStorage[key]
    }

    @inline(__always) func cache(signature: Int) -> MsgsScrollViewLayout.Cache? {
        layoutStorage[signature]
    }

    func setSize(_ size: CGSize, for key: MsgsScrollViewLayout.SizeKey) {
        sizeStorage[key] = size
    }

    func setCache(_ cache: MsgsScrollViewLayout.Cache, signature: Int ) {
        if layoutStorage.count > 3 {
            layoutStorage = [:]
        }
        layoutStorage[signature] = cache
    }
}
