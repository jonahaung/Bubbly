//
//  ListPickerSection.swift
//  XUI
//
//  Created by Aung Ko Min on 25/5/26.
//


import SwiftUI

struct ListPickerSection<Item: Identifiable>: Identifiable {

    init(title: String, items: [Item]) {
        self.id = UUID()
        self.title = title
        self.items = items
    }

    let id: UUID
    let title: String
    let items: [Item]

    @ViewBuilder
    var header: some View {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            EmptyView()
        } else {
            Text(title)
        }
    }
}
