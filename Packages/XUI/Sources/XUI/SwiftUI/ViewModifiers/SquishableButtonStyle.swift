//
//  SquishableButtonStyle.swift
//  XUI
//
//  Created by Aung Ko Min on 10/11/24.
//

import SwiftUI

public struct SquishableButtonStyle: ButtonStyle {
    var fadeOnPress = true
    var scale: CGFloat = 0.98

    public init(fadeOnPress: Bool = true, scale: CGFloat = 0.98) {
        self.fadeOnPress = fadeOnPress
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && fadeOnPress ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? scale : 1)
    }
}

public extension ButtonStyle where Self == SquishableButtonStyle {
    static var squishable: SquishableButtonStyle {
        SquishableButtonStyle()
    }

    static func squishable(fadeOnPress: Bool = true, scale: CGFloat = 0.98) -> SquishableButtonStyle {
        SquishableButtonStyle(fadeOnPress: fadeOnPress, scale: scale)
    }
}
