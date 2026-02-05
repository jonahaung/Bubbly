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
			"microphone.and.signal.meter.fill"
		case .machineImag:
			"apple.intelligence"
		case .text:
			"text.line.2.summary"
		case .liary:
			"photo.stack.fill"
		case .camera:
			"camera.viewfinder"
		case .document:
			"text.document"
		case .emoji:
			"heart.fill"
		case .menu:
			"plus"
		}
	}

	var foreGroundStyle: AnyShapeStyle {
		switch self {
		case .camera, .liary, .audio, .text, .menu, .document:
			AnyShapeStyle(
				Color.accentColor.gradient
			)
		case .machineImag:
			AnyShapeStyle(AngularGradient(
				gradient: Gradient(
					colors:[.indigo, .blue, .red, .orange, .indigo]
				),
				center: .center
			))
		case .emoji:
			AnyShapeStyle(
				Color.red.gradient
			)
		}

	}
}
