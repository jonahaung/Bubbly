//  BackgroundView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI

struct BackgroundView: View {
    let imageName: String
    var body: some View {
        Rectangle().fill(Color.background)
            .overlay {
                Image(imageName)
                    .resizable(resizingMode: .tile)
                    .foregroundStyle(Color.container)
                    .clipped()
            }
            .ignoresSafeArea(.all)
            .allowsHitTesting(false)
            .geometryGroup()
            .equatable(by: imageName)
    }
}
