//
//  XPhotoPageControl.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 4/7/23.
//

import SwiftUI

public struct XPhotoPageControl: View {
    @Binding private var selection: Int
    private let length: Int
    private let size: CGFloat

    public init(selection: Binding<Int>, length: Int, size: CGFloat) {
        _selection = selection
        self.length = length
        self.size = size
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 0.5) {
            ForEach(0 ... length - 1) { i in
                let isSelected = selection == i
                if isSelected {
                    Image(systemName: "\(i + 1).circle")
                        .frame(square: size)
                } else {
                    Circle()
                        .frame(square: size / 1.5)
                }
            }
        }
        .equatable(by: selection)
    }
}
