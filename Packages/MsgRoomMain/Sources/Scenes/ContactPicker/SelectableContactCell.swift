//
//  SelectableContactCell 2.swift
//  Bubbly
//
//  Created by Aung Ko Min on 20/8/25.
//

import Database
import Services
import SwiftUI
import XUI

struct SelectableContactCell: View {
    let contact: Contact
    let isSelected: Bool
    let onSelected: (Bool) -> Void

    var body: some View {
        Button {
            onSelected(!isSelected)
        } label: {
            HStack(spacing: 20) {
                ProfilePhoto(contact)
                    .frame(square: 30)
                    .padding(.vertical, 2)
                Text(contact.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SystemImage(
                    isSelected ? .checkmarkCircleFill : .circle,
                    20
                )
                .foregroundStyle(
                    isSelected ? Color.accentColor : .secondary
                )
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.primary)
    }
}
