//
//  ComposeTypeButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import SwiftUI
import XUI

extension ComposeBar {

	@MainActor
	struct ComposeBarSourceButton: View {
		let source: ChatComposer.Source
		@Environment(ChatComposer.self) private var composer

		var body: some View {
			Button(action: action) {
				buttonIcon(for: source.systemImageName)
			}
			.frame(square: 44)
			.background(.windowBackground, in: .circle)
			.equatable(by: source)
		}
		private func buttonIcon(for systemName: String) -> some View {
			Image(systemName: systemName)
				.resizable()
				.scaledToFit()
				.frame(width: 24, height: 24).foregroundStyle(foreGroundStyle())
		}
		private func action() {
			if composer.source == source {
				composer.source = composer.source == .text ? .menu : .text
			} else {
				composer.source = source
			}
		}

		private func foreGroundStyle() -> AnyShapeStyle {
			switch source {
			case .camera:
				AnyShapeStyle(AngularGradient(
					gradient: Gradient(
						colors:[.accentColor, .orange, .blue]
					),
					center: .center
				))
			case .liary:
				AnyShapeStyle(
					LinearGradient(
						colors: [.red, .accentColor, .orange],
						startPoint: .bottomLeading,
						endPoint: .topTrailing
					)
				)
			case .audio:
				AnyShapeStyle(
					LinearGradient(
						colors: [.accentColor, .orange, .yellow],
						startPoint: .bottomLeading,
						endPoint: .topTrailing
					)
				)
			case .emoji:
				AnyShapeStyle(
					Color.red.gradient
				)
			case .machineImag:
				AnyShapeStyle(AngularGradient(
					gradient: Gradient(
						colors:[.indigo, .blue, .red, .orange, .indigo]
					),
					center: .center
				))
			default:
				AnyShapeStyle(
					LinearGradient(
						colors: [.accentColor, .systemBackground],
						startPoint: .bottomLeading,
						endPoint: .topTrailing
					)
				)
			}

		}
	}
}
