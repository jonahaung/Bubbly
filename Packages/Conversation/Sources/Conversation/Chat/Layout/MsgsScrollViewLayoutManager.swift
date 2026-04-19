//
//  MsgsScrollViewLayoutManager.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/4/26.
//

import Database
import SwiftUI
import XUI
import UIKit

final class MsgsScrollViewLayoutManager {
    let cache: MsgsScrollViewLayoutCache
    private(set) var selectedMsg: SelectedMsg?

    init(cache: MsgsScrollViewLayoutCache) {
        self.cache = cache
    }

    func updateSelectedMsg(_ newValue: SelectedMsg?) {
        selectedMsg = newValue
    }
}
