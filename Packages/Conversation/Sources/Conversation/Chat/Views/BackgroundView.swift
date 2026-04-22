//  BackgroundView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI

struct BackgroundView: View {
    let imageName: String
    var body: some View {
        Color.background
            .overlay {
                Image(imageName)
                    .resizable()
                    .aspectRatio(UIApplication.shared.screenScale(), contentMode: .fit)
                    .foregroundStyle(Color.container)
            }
            .ignoresSafeArea(.keyboard)
            .backgroundExtensionEffect()
            .allowsHitTesting(false)
            .equatable(by: imageName)
    }
}
