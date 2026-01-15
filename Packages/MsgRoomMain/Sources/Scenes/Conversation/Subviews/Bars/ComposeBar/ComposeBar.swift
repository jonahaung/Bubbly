//
//  ChatComposerBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import AVKit
import Database
import MediaPicker
import PhotosUI
import Services
import SFSafeSymbols
import SwiftUI
import XUI
import ImageLoader

struct ComposeBar: View {

	@Bindable var composer: ChatComposer
	@Environment(\.conversationTheme) private var theme
	@Environment(\.conversation) private var conversation
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(\.sharedFocusState) private var sharedFocus
	@Environment(\.sharedNamespace) private var namespace
	@Environment(ChatViewManager.self) private var manager

	var body: some View {
		HStack(alignment: .bottom, spacing: 4) {
			MenuBar(composer: composer)
			textField()
			SendButton()
		}
		.padding(8)
		.background(
			theme.backgroundColor,
			ignoresSafeAreaEdges: [.bottom, .leading, .trailing]
		)
		.transaction(value: composer.composeType) { transaction in
			if manager.scrollController.isUserScrolling {
				transaction.tracksVelocity = true
			} else {
				transaction.animation = .spring(duration: 0.15)
			}
			transaction.isContinuous = false
		}
		.sensoryFeedback(
			.impact(flexibility: .rigid, intensity: 0.7),
			trigger: sharedFocus?.value
		)
		.geometryGroup()
		.equatable(by: composer.reloadID)
	}

	private func photoPickerControls() -> some View {
		HStack(alignment: .center, spacing: 4) {
			Button {
				composer.photoPicker.removeAll()
				composer.attachments.removeAll()
			} label: {
				SystemImage(.trashFill)
					.padding(4)
			}
			.buttonStyle(.borderedProminent)

			Button {
				composer.send(conversation: conversation)
			} label: {
				Text("Send")
			}
			.buttonStyle(.roundedButtonStyle)
			.buttonSizing(.flexible)
			.layoutPriority(1)
		}
	}
	let fontSize = CGFloat(16)
	private func textField() -> some View {
		ZStack {
			ContainerRelativeShape()
				.strokeBorder(
					textFieldStrokeBorder.opacity(sharedFocus?.value != nil ? 0.8 : 0.6),
					lineWidth: 2, antialiased: false)
			TextField(
				text: $composer.inputText.text,
				prompt: Text("\(Image(systemSymbol: composer.composeType.systemSymbol))"),
				axis: .vertical) {
					Text("TextField")
				}
				.labelsHidden()
				.lineLimit(1...5)
				.font(Font.system(size: fontSize, design: .default))
				.lineSpacing(0)
				.lineHeight(.multiple(factor: 1.2))
				.focused(
					sharedFocus.unsafelyUnwrapped.binding,
					equals: composer.composeType.rawValue
				)
				.padding(.init(top: 7, leading: 16, bottom: 7, trailing: 8))
				.layoutPriority(1)
		}
		.symbolRenderingMode(.multicolor)
		.containerShape(RoundedRectangle(cornerRadius: 15.5))
	}

	private var textFieldStrokeBorder: AnyShapeStyle {
		if composer.composeType == .machineImag {
			return AnyShapeStyle(
				AngularGradient.colorful
			)
		} else {
			return AnyShapeStyle(Color.accentColor)
		}
	}
}

extension AngularGradient {
	static let colorful: AngularGradient = {
		AngularGradient(
			gradient: Gradient(
				colors:  [.indigo, .blue, .red, .orange, .indigo]
			),
			center: .center,
			startAngle: .degrees(0),
			endAngle: .degrees(360)
		)
	}()
}
