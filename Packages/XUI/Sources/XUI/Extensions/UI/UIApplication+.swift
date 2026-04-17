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
        if let first = windowScene.windows.first, let viewController = first.rootViewController {
            return viewController.view.bounds.inset(by: viewController.view.safeAreaInsets).integral.size
        }
        return windowScene.screen.bounds.inset(by: UIApplication.safeAreInset).integral.size
    }
    
    func screenScale() -> CGFloat {
        let size = screenSize()
        return size.width/size.height
    }
}
public extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
    }
    
    static var safeAreInset: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .init()
    }
}

private extension UIEdgeInsets {
    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
