//
//  ChatViewLayout.swift
//  Conversation
//
//  Created by Aung Ko Min on 13/3/26.
//

import SwiftUI
import XUI
import Database

@Observable
final class ChatViewLayout {
	private(set) var bottomBarFrame: CGRect?
	var selectedMsg: SelectedMsg?

	func update(bottomBarFrame: CGRect) {
		self.bottomBarFrame = bottomBarFrame
	}
}
