//  PhotoPickerButton.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Services

struct PhotoPickerButton: View {
    var photoPicker = PhotoPickerManager()
    var body: some View {
        CustomButton {
            composer.updateSource(.liary)
        } label: {
            Image(systemName: ChatComposer.Source.liary.systemImageName)
                .resizable()
                .frame(square: 20)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
        } onFinished: {
            manager.router?
                .presentModel(
                    NavPath
                        .view(
                            node: PhotoPickerView().environment(photoPicker).opaqueView()
                        )
                )
        }
    }

    @Environment(ChatComposer.self) private var composer
    @Environment(ChatManager.self) private var manager
}
