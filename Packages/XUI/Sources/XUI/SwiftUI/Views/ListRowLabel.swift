//
//  ListRowLabel.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 28/7/23.
//

import SFSafeSymbols
import SwiftUI

public struct ListRowLabel: View {
    private let icon: SFSymbol?
    private let iconStyle: SystemImageWithShape.IconStyle
    private let text: String

    public init(
        _ icon: SFSymbol?,
        _ iconStyle: SystemImageWithShape.IconStyle = .square(.plain),
        text: String
    ) {
        self.icon = icon
        self.iconStyle = iconStyle
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 0) {
            if let icon {
                SystemImageWithShape(icon, iconStyle)
                    .padding(.trailing)
            }
            Text(.init(text))
                .fixedSize()
                .foregroundStyle(Color.primary)
            Color.clear
        }
    }
}
