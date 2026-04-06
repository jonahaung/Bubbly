//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct ViewDidLoadModifier: ViewModifier {
    @State private var didLoad = false
    private let action: () -> Void

    public init(perform action: @escaping () -> Void) {
        self.action = action
    }

    public func body(content: Content) -> some View {
        content.onAppear {
            if self.didLoad == false {
                self.didLoad = true
                self.action()
            }
        }
    }
}

public struct ViewDidTaskModifier: ViewModifier {
	@State private var didTask = false
	private let action:  () async -> Void

	public init(perform action: @escaping () async -> Void) {
		self.action = action
	}

	public func body(content: Content) -> some View {
		content.task {
			if didTask == false {
				didTask = true
				await action()
			}
		}
	}
}


public extension View {
    func onLoad(perform action: @escaping () -> Void) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
	func onTask(perform action: @escaping () async -> Void) -> some View {
		modifier(ViewDidTaskModifier(perform: action))
	}
}
