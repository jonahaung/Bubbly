//
//  DeferredView.swift
//  XUI
//
//  Created by Aung Ko Min on 17/4/26.
//

import SwiftUI

@frozen
@_documentation(visibility: internal)
public struct DeferredView<Content: View>: View {
    @usableFromInline
    let content: () -> Content

    @usableFromInline
    @State var didAppear: Bool = false
    @usableFromInline
    @State var didAppear2: Bool = false

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
