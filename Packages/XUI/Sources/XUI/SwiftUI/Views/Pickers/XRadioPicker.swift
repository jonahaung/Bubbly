//
//  XRadioPicker.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 12/8/23.
//

import SwiftUI

public struct XRadioPicker<Item: XPickable>: View {
    private let items: [Item]
    private var selection: Binding<Item>

    public init(_ _items: [Item], _ _selection: Binding<Item>) {
        items = _items
        selection = _selection
    }

    public var body: some View {
        Group {
            ForEach(items) { item in
                AsyncButton {
                    Haptics.play(.rigid, 0.9)
                    selection.wrappedValue = item
                } label: {
                    HStack {
                        SystemImage(item == selection.wrappedValue ? .circleInsetFilled : .circle)
                        Text(item.title)
                            .accentColor(.primary)
                    }
                }
            }
        }
    }
}
