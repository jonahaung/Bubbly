//
//  GroupedSectionStyle.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 3/4/23.
//

import SwiftUI

private struct GroupedSectionStyle: ViewModifier {

    let innerPadding: CGFloat
    let cornorRadius: CGFloat
    let paddingH: CGFloat
    let paddingV: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(innerPadding)
            .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
            .cornerRadius(cornorRadius)
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .shadow(color: .black.opacity(0.2), radius: paddingH, x: 0, y: paddingV)
    }
}

public extension View {
    func _groupedSectionStyle(innerPadding: CGFloat = 0, cornorRadius: CGFloat = 0, paddingH: CGFloat = 5, paddingV: CGFloat = 5) -> some View {
        ModifiedContent(content: self, modifier: GroupedSectionStyle(innerPadding: innerPadding, cornorRadius: cornorRadius, paddingH: paddingH, paddingV: paddingV))
    }
}
