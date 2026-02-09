//
//  ContactDetailsScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 15/6/25.
//

import Database
import SwiftUI

public struct ContactDetailsScene: View {
	let contact: Contact
	public init(contact: Contact) {
		self.contact = contact
	}

	public var body: some View {
		Form {
			Section {
				Text(contact.preetyPrinted)
			} header: {
				ProfilePhoto(contact, size: .original)
			}
		}
	}
}
