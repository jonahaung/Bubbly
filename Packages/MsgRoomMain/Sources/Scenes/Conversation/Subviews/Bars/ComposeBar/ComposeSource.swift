//
//  ComposeType.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import Foundation
import Database
import XUI
import SFSafeSymbols
import SwiftUI

enum ComposeSource: String, Hashable, Identifiable {
	var id: Self { self }
	case text, camera, liary, audio, document, machineImag
}

extension ComposeSource {
	var systemSymbol: SFSymbol {
		switch self {
		case .audio:
				.micFill
		case .machineImag:
				.init(rawValue: "apple.writing.tools")
		case .text:
				.init(rawValue: "character.cursor.ibeam")
		case .liary:
				.photoFill
		case .camera:
				.cameraFill
		case .document:
				.init(rawValue: "paperclip")
		}
	}

	var isFoundationType: Bool {
		self == .machineImag
	}

	var canBecomeFirstResponder: Bool {
		self == .machineImag
	}
}
