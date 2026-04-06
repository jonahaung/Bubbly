#if os(iOS)
//
//  PhotoPickerButton.swift
//  Conversation
//
//  Created by Aung Ko Min on 3/4/26.
//

import SwiftUI
import XUI
import Services

struct PhotoPickerButton: View {

	@Environment(ChatComposer.self) private var composer
	@Environment(ChatManager.self) private var manager

    var body: some View {
		CustomButton {
			composer.updateSource(.liary)
		} label: {
			Image(systemName: ChatComposer.Source.liary.systemImageName)
				.resizable()
				.frame(square: 20)
				.padding()
				.frame(square: 38)
				.background(.windowBackground, in: .circle)
		} onFinished: {
			Router.shared
				.presentModel(
					NavPath
						.view(
							node: PhotoPickerView().environment(composer.photoPicker).opaqueView()
						)
				)
		}
    }
}

#endif
