// © 2026 Aung Ko Min

import SwiftUI

public struct AppIcon: View {
    private let size: CGFloat

    public init(_ size: CGFloat) {
        self.size = size
    }

    public var body: some View {
        Image("App")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.accentColor)
        //		ZStack {
        //			AppIconShape()
        //				.fill(Color(.systemGray2).gradient)
        //				.frame(width: size, height: size)
        //				.rotationEffect(.degrees(15))
        //				.shadow(color: AppColor.shadow, radius: 4, x: 2, y: 2)
        //			AppIconShape()
//
        //				.frame(width: size/bubbleRatio, height: size/bubbleRatio)
        //				.rotationEffect(.degrees(-20))
        //				.offset(x: size/4, y: -(size/6))
        //				.shadow(color: AppColor.shadow, radius: 4, x: 2, y: 2)
        //		}
    }
}
