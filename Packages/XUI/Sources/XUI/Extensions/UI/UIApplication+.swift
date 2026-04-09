//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func screenSize() -> CGSize {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("explanation")
        }
        return windowScene.windows.first?.rootViewController?.view.frame.size ?? windowScene.screen
            .bounds.size
    }
}
