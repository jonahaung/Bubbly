// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

struct PhotoPickerButton: View {
    

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
                            node: PhotoPickerView().environment(composer.photoPicker).opaqueView(),
                        ),
                )
        }
    }

    

    @Environment(ChatComposer.self) private var composer
    @Environment(ChatManager.self) private var manager
}
