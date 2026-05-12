//  UIApplication+.swift
//
//  Copyright © 2025 Aung Ko Min.
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
       screenBounds().size
    }
    func screenBounds() -> CGRect {
        guard let keyWindow else {
            fatalError()
        }
        if let viewController = keyWindow.rootViewController {
            return viewController.view.bounds.inset(by: viewController.view.safeAreaInsets)
        }
        return windowScene.screen.bounds.inset(by: UIApplication.safeAreInset)
    }
    func screenScale() -> CGFloat {
        let size = screenSize()
        return size.width / size.height
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
