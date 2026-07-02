//
//  ListPickerItem.swift
//  XUI
//
//  Created by Aung Ko Min on 25/5/26.
//


import SwiftUI

protocol ListPickerItem: View {

    associatedtype Item: Equatable

    var item: Item { get }
    var isSelected: Bool { get }
}

extension ListPickerItem {

    var checkmark: some View {
        Image(systemName: "checkmark")
            .opacity(isSelected ? 1 : 0)
    }
}
