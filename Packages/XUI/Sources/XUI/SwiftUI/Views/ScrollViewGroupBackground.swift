//
//  ScrollViewGroupBackground.swift
//  XUI
//
//  Created by Aung Ko Min on 26/11/24.
//

import SwiftUI

public struct ScrollViewGroupBackground: View {
    public init() {}
    public var body: some View {
        Color.systemGroupedBackground
            .ignoresSafeArea(edges: .all)
    }
}
