//  MsgsScrollViewLayoutManager.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftUI
import UIKit
import XUI

final class MsgsScrollViewLayoutManager: @unchecked Sendable {
    private var sizeCache = [Int: [MsgLayoutValue: CGSize]]()
    private var layoutCache: MsgsScrollViewLayout.Cache?
}
extension MsgsScrollViewLayoutManager {
    @inline(__always) func size(for key: MsgLayoutValue, boundsWidth: Int)
        -> CGSize?
    {
        sizeCache[boundsWidth]?[key]
    }

    @inline(__always) func cache(for key: Int) -> MsgsScrollViewLayout.Cache? {
        layoutCache?.signatureHash == key ? layoutCache : nil
    }

    func setSize(_ size: CGSize, for key: MsgLayoutValue, boundsWidth: Int) {
        sizeCache[boundsWidth, default: [:]][key] = size
    }

    func setCache(_ cache: MsgsScrollViewLayout.Cache) {
        layoutCache = cache
    }
    @inline(__always)
    var uncheckedCache: MsgsScrollViewLayout.Cache? { layoutCache }
}
