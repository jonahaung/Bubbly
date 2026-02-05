//
//  ComposeType.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import Foundation
import Database
import XUI
import SwiftUI

extension ChatComposer {
	enum Source: String, Hashable, Identifiable, Equatable, CaseNameReflectable {
		var id: Self { self }
		case menu, text, camera, liary, audio, document, machineImag, emoji
	}
}
extension ChatComposer.Source {
	var systemImageName: String {
		switch self {
		case .audio:
			"mic.fill"
		case .machineImag:
			"apple.intelligence"
		case .text:
			"text.line.2.summary"
		case .liary:
			"photo.stack"
		case .camera:
			"camera.aperture"
		case .document:
			"text.document"
		case .emoji:
			"heart.fill"
		case .menu:
			"plus"
		}
	}
}
