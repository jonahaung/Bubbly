//
//  File.swift
//
//
//  Created by Aung Ko Min on 6/8/23.
//

import SwiftUI
import Combine

public extension View {
    func observeKeyboardVisibility() -> some View {
        modifier(KeyboardVisibility())
    }
}
public struct KeyboardShowingEnvironmentKey: EnvironmentKey {
    public static let defaultValue = CGFloat.zero
}
public extension EnvironmentValues {
    var keyboardHeight: CGFloat {
        get { self[KeyboardShowingEnvironmentKey.self] }
        set { self[KeyboardShowingEnvironmentKey.self] = newValue }
    }
}
private struct KeyboardVisibility: ViewModifier {
    @State var keyboardHeight = CGFloat.zero
    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { value in
                        guard let frame = value.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                            return 0
                        }
                        return frame.maxY - frame.minY
                    },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in
                        return 0
                    })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .environment(\.keyboardHeight, keyboardHeight)
            .onReceive(keyboardHeightPublisher) { value in
                keyboardHeight = value
            }
    }
}
public struct HideKeyboardKey: EnvironmentKey {
	nonisolated(unsafe) public static let defaultValue: () -> Void = {}
}
public extension EnvironmentValues {
	var hideKeyboard: () -> Void {
		get { self[HideKeyboardKey.self] }
		set { self[HideKeyboardKey.self] = newValue }
	}
}
public extension View {
	func withHideKeyboard() -> some View {
		environment(\.hideKeyboard) {
			UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
											to: nil,
											from: nil,
											for: nil)
		}
	}
}
