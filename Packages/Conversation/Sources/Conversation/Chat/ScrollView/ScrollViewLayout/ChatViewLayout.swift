// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

@Observable
final class ChatViewLayout {
    private(set) var bottomBarFrame: CGRect? = nil
    var selectedMsg: SelectedMsg? = nil

    func update(bottomBarFrame: CGRect) {
        self.bottomBarFrame = bottomBarFrame
    }
}
