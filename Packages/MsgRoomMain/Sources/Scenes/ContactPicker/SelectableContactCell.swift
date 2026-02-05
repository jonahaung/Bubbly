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
			let badgeView = Text("\(Image(systemName: isSelected ? "checkmark.circle.fill" : "circle"))")
			Label {
				Text(contact.name)
			} icon: {
				ProfilePhoto(contact, size: .mini)
			}
			.badge(badgeView)
			.badgeProminence(isSelected ? .standard : .decreased)
		}
		.buttonStyle(.borderless)
	}
}
