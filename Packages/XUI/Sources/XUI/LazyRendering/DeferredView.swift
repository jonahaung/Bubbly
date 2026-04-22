//  DeferredView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@frozen
@_documentation(visibility: internal)
public struct DeferredView<Content: View>: View {
    @usableFromInline
    let content: () -> Content

    @State private var didAppear: Bool = false

    @State private var didAppear2: Bool = false

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        Group {
            if didAppear2 {
                content()
            } else if didAppear {
                ZeroSizeView().onAppear {
                    if !didAppear2 {
                        didAppear2 = true
                    }
                }
            } else {
                ZeroSizeView()
                    .onAppear {
                        if !didAppear {
                            didAppear = true
                        }
                    }
            }
        }
        .transaction { transaction in
            if !(didAppear && didAppear2) {
                transaction.disablesAnimations = true
            }
        }
    }
}
