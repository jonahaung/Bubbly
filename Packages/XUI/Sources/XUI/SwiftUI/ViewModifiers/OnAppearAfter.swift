//
//  OnAppearAfter.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 26/4/23.
//

import SwiftUI

private struct OnAppearAfterModifier: ViewModifier {

    private let timeout: TimeInterval
    private let perform: () -> Void

    public init(timeout: TimeInterval, perform: @escaping () -> Void) {
        self.timeout = timeout
        self.perform = perform
    }

    public func body(content: Content) -> some View {
        content
            .task {
                try? await Task.sleep(for: .seconds(timeout))
                perform()
            }
    }
}

public extension View {
    func _onAppear(after timeout: TimeInterval, _ perform: @escaping () -> Void) -> some View {
        modifier(OnAppearAfterModifier(timeout: timeout, perform: perform))
    }
}
