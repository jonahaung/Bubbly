//
//  ContactProfileScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 15/6/25.
//

import SwiftUI
import Database

public struct ContactDetailsScene: View {
	let contact: ContactSnapshot
	public init(contact: ContactSnapshot) {
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
