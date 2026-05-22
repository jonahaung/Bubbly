//  View++.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension View {
    func rectReader(_ binding: Binding<CGRect>, in coordinatorSpace: CoordinateSpace = .global) -> some View {
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
}
