//
//  ProfileBackgroundShape.swift
//  XUI
//
//  Created by Aung Ko Min on 6/4/26.
//

import SwiftUI

public struct ProfileBackgroundShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height / 2))
            path
                .addCurve(
                    to: CGPoint(x: width, y: height / 1.7),
                    control1: CGPoint(x: width * 1 / 3, y: height),
                    control2: CGPoint(x: width * 2 / 3, y: height / 4.5),
                )
            path.addLine(to: CGPoint(x: width, y: 0))
        }
    }
}
