//
//  ChatComposeBarAttachmentMenu.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import SwiftUI
import Database
import Services
import XUI
import PhotosUI

extension ComposeBar {
	struct MenuBar: View {
		@Bindable var composer: ChatComposer
		@Environment(\.sharedNamespace) private var namespace
		@Environment(\.sharedFocusState) private var sharedFocus

		var body: some View {
			HStack(spacing: 8) {
				switch composer.menuVisibility {
				case .visible:
					HStack(spacing: 4) {
						ForEach(
							[
								ComposeSource.camera,
								.liary,
								.audio,
								.document,
								.machineImag
							]
						) { type in
							SourceButton(source: type)
								.matchedGeometryEffect(
									id: type.rawValue,
									in: namespace.forceUnwrapped.value
								)
						}
					}
					.transition(.scale(scale: 0, anchor: .leading).combined(with: .opacity))
				default:
					if composer.composeType == .text {
						plusButton()
					} else {
						closeButton()
					}
				}
			}
			.onChange(of: sharedFocus?.value) { (oldValue, newValue) in
				if newValue == nil && !composer.inputText.hasText {
					composer.menuVisibility = .visible
				} else {
					composer.menuVisibility = .hidden
				}
			}
			.geometryGroup()

		}

		private func plusButton() -> some View {
			Button {
				withTransaction(.withAnimation(.easeInOut)) {
					composer.menuVisibility = .visible
				}
			} label: {
				SystemImage(.plusCircleFill, 30)
			}
			.matchedGeometryEffect(
				id: ComposeSource.machineImag.rawValue,
				in: namespace.forceUnwrapped.value
			)
		}
		private func closeButton() -> some View {
			Button {
				composer.composeType = .text
			} label: {
				ZStack {
					SystemImage(.minusCircleFill, 22)
				}
				.frame(square: 30)
				.symbolRenderingMode(.multicolor)
			}
			.matchedGeometryEffect(
				id: composer.composeType.rawValue,
				in: namespace.forceUnwrapped.value
			)
		}
	}

}
