//
//  ComposeTypeButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import SwiftUI
import XUI
import SFSafeSymbols
import PhotosUI

extension ComposeBar {
	struct SourceButton: View {
		let source: ComposeSource
		@Environment(ChatComposer.self) private var composer
		@Environment(\.sharedFocusState) private var sharedFocus
		
		var body: some View {
			switch source {
			case .liary:
				photoPicker()
			default:
				Button {
					toggle()
				} label: {
					ComposeTypeIcon(source)
				}
			}
		}
		
		private var isSelected: Bool {
			composer.composeType == source
		}
		private func toggle() {
			if isSelected {
				composer.composeType = .text
				composer.menuVisibility = .visible
			} else {
				composer.menuVisibility = .hidden
				composer.composeType = source
				if composer.composeType.canBecomeFirstResponder {
					sharedFocus?.focus(ComposeSource.text.rawValue)
				}
			}
		}
		
		private func photoPicker() -> some View {
			PhotosPicker.init(
				selection: composer.photoPicker.photoPickerItems,
				maxSelectionCount: 5,
				selectionBehavior: .continuousAndOrdered,
				preferredItemEncoding: .automatic,
				photoLibrary: .shared()) {
					MainActor.assumeIsolated {
						ComposeTypeIcon(ComposeSource.liary)
					}
				}
		}
	}
}

struct ComposeTypeIcon: View {
	
	let systemSymbol: SFSymbol
	let size: CGFloat
	
	init(_ type: ComposeSource) {
		systemSymbol = type.systemSymbol
		size = 30
	}
	init(_ symbol: SFSymbol, size: CGFloat = 30) {
		systemSymbol = symbol
		self.size = size
	}
	var body: some View {
		ZStack {
			Circle()
			Image(systemSymbol: systemSymbol)
				.symbolColorRenderingMode(.gradient)
				.resizable()
				.scaledToFit()
				.foregroundStyle(Color.white)
				.imageScale(.small)
				.frame(square: size/1.9)
		}
		.frame(square: size)
	}
}
