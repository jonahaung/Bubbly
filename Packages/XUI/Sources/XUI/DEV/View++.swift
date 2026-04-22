//  View++.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension View {
    func on(_ platforms: Platform..., transform: (Self) -> some View) -> AnyView {
        guard platforms.contains(Platform.current) else { return anyView }
        return transform(self).anyView
    }

    var anyView: AnyView { AnyView(self) }

    func rectReader(_ binding: Binding<CGRect>, in coordinatorSpace: CoordinateSpace = .local) -> some View {
        background(
            GeometryReader { geometry -> Color in
                let rect = geometry.frame(in: coordinatorSpace)
                DispatchQueue.main.async {
                    binding.wrappedValue = rect
                }
                return .clear
            }
        )
    }

    func applyBackground(_ color: Color = .background) -> some View {
        ZStack {
            color
                .ignoresSafeArea(.all)
            self
        }
    }
}
