//  MsgsScrollViewLayoutManager.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import UIKit
import SwiftUI
import Database

final class MsgsScrollViewLayoutManager: @unchecked Sendable {
    let cache: MsgsScrollViewLayoutCache
    private(set) var selectedMsg: SelectedMsg?

    init(cache: MsgsScrollViewLayoutCache) {
        self.cache = cache
    }

    func updateSelectedMsg(_ newValue: SelectedMsg?) {
        selectedMsg = newValue
    }
}
