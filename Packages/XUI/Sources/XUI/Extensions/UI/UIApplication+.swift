//  UIApplication+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

extension UIApplication {
    public func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    public var windowScene: UIWindowScene {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene
        else {
            fatalError("explanation")
        }
        return windowScene
    }

    public var keyWindow: UIWindow? {
        windowScene.keyWindow
    }

    public func screenSize() -> CGSize {
        screenBounds().size
    }
    public func screenBounds() -> CGRect {
        guard let keyWindow else {
            fatalError()
        }
        if let viewController = keyWindow.rootViewController {
            return viewController.view.bounds.inset(
                by: viewController.view.safeAreaInsets
            )
        }
        return windowScene.screen.bounds.inset(by: UIApplication.safeAreInset)
    }
    public func screenScale() -> CGFloat {
        let size = screenSize()
        return size.width / size.height
    }

    public var statusBarHeight: CGFloat {
        windowScene.statusBarManager?.statusBarFrame.height ?? .zero
    }
}

extension UIApplication {
    public static var safeAreInset: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .init()
    }
}

extension UIEdgeInsets {
    fileprivate var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
