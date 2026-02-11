//
//  UIApplication+.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 27/1/23.
//

import SwiftUI

public extension UIApplication {
	func endEditing() {
		sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}

	func screenSize() -> CGSize {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
			fatalError()
		}
		return windowScene.windows.first?.rootViewController?.view.frame.size ?? windowScene.screen.bounds.size
	}
}
