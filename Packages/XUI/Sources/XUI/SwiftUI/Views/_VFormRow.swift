//
//  XFormRow.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import SwiftUI

public struct _VFormRow<Content: View>: View {

    private let title: String
    private let isEmpty: Bool
    private let content: () -> Content

    public init(title: String, isEmpty: Bool, content: @escaping () -> Content) {
        self.title = title
        self.isEmpty = isEmpty
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(.init(title))
                .foregroundStyle(isEmpty ? .primary : .tertiary)
            content()
        }
    }
}
