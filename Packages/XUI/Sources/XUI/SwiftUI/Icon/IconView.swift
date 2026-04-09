//
//  IconView.swift
//  XUI
//
//  Created by Aung Ko Min on 10/3/26.
//

import SwiftUI

public struct IconView<Content: View>: View {

    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(.primary)
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 28, height: 28)
                .brightness(colorScheme == .dark ? -0.2 : -0.03)

            content
				.foregroundStyle(Color(.tertiarySystemBackground))
        }
        .font(.system(size: 18))
        .imageScale(.small)
        .symbolRenderingMode(.monochrome)
        .symbolVariant(.fill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                .blendMode(.plusLighter)
        }
    }
}
