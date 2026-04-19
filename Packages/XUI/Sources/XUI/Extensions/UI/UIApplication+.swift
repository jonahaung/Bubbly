//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var windowScene: UIWindowScene {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("explanation")
        }
        return windowScene
    }
    var keyWindow: UIWindow? {
        windowScene.keyWindow
    }
    func screenSize() -> CGSize {
        guard let keyWindow else {
            fatalError()
        }
        if let viewController = keyWindow.rootViewController {
            return viewController.view.bounds.inset(by: viewController.view.safeAreaInsets).size
        }
        return windowScene.screen.bounds.inset(by: UIApplication.safeAreInset).integral.size
    }
    
    func screenScale() -> CGFloat {
        let size = screenSize()
        return size.width/size.height
    }
    
    var statusBarHeight: CGFloat {
        windowScene.statusBarManager?.statusBarFrame.height ?? .zero
    }
}
public extension UIApplication {
    static var safeAreInset: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .init()
    }
}

private extension UIEdgeInsets {
    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
