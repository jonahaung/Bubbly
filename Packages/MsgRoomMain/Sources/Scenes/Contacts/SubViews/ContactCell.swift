//
//  ContactCell.swift
//  Bubbly
//
//  Created by Aung Ko Min on 14/7/25.
//

import SwiftUI
import Database
import Services
import XUI
import Core

struct ContactCell: View {

	let contact: Contact
	var onTap: (() -> Void)?

	init(_ contact: Contact, onTap: (() -> Void)? = nil) {
		self.contact = contact
		self.onTap = onTap
	}

	var body: some View {
		Button {
			onTap?()
		} label: {
			HStack(spacing: 20) {
				ProfilePhoto(contact, size: .custom(25))
					.padding(.vertical, 2)
				Text(contact.name)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.foregroundStyle(Color.primary)
		.buttonStyle(.borderless)
	}

	private var isEnabled: Bool {
		contact.isChatAvailable && contact.uid != currentUserId
	}
}
