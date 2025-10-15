//
//  AlignedStack.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 10/7/23.
//

import SwiftUI

public struct AlignedStack<Content: View>: View {

    private let alignment: Alignment
    @ViewBuilder private var content: () -> Content

    public init(_ alignment: Alignment, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        Group {
            switch alignment {
            case .leading:
                HStack {
                    content()
                    Spacer()
                }
            case .trailing:
                HStack {
                    Spacer()
                    content()
                }
            case .top:
                VStack {
                    content()
                    Spacer()
                }
            case .bottom:
                VStack {
                    Spacer()
                    content()
                }
            case .center:
                HStack {
                    Spacer()
                    content()
                    Spacer()
                }
            case .topLeading:
                VStack {
                    HStack {
                        content()
                        Spacer()
                    }
                    Spacer()
                }
            case .topTrailing:
                VStack {
                    HStack {
                        Spacer()
                        content()
                    }
                    Spacer()
                }
            case .bottomLeading:
                VStack {
                    Spacer()
                    HStack {
                        content()
                        Spacer()
                    }
                }
            case .bottomTrailing:
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        content()
                    }
                }
            default:
                content()
            }
        }
    }
}
