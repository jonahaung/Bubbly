// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

// MARK: - ComposerSourceButton

struct ComposerSourceButton: View {
    

    let source: ChatComposer.Source

    var body: some View {
        CustomButton {
            composer.updateSource(source)
        } label: {
            Image(systemName: source.systemImageName)
                .resizable()
                .scaledToFit()
                .frame(square: 20)
                .symbolRenderingMode(.multicolor)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
        } onFinished: {
            action()
        }
    }

    

    @Environment(ChatComposer.self) private var composer
    @Environment(ChatManager.self) private var manager
}

extension ComposerSourceButton {
    private func action() {
        @Bindable var composer = composer
        switch source {
        case .camera:
            manager.router?
                .presentModel(
                    NavPath
                        .view(
                            node: CameraPicker { pickedItem in
                                switch pickedItem {
                                case let pickedItem as ImageCameraPickerItem:
                                    Task { @MainActor in
                                        await composer
                                            .parseImages(
                                                selectedImages: [
                                                    .init(
                                                        id: pickedItem.id.uuidString,
                                                        image: pickedItem
                                                            .underlyingMediaType,
                                                    ),
                                                ],
                                            )
                                    }
                                case let pickedItem as MovieCameraPickerItem:
                                    print(pickedItem)
                                default:
                                    break
                                }
                            }
                            .opaqueView(),
                        ),
                )
        case .liary:
            manager.router?
                .presentModel(
                    NavPath
                        .view(
                            node: PhotoPickerView()
                                .environment(composer.photoPicker)
                                .opaqueView(),
                        ),
                )
        case .audio:
            break
        case .document:
            manager.router?
                .presentModel(
                    NavPath
                        .view(
                            node: DocumentPicker(fileContent: $composer.fileContent)
                                .environment(composer.photoPicker)
                                .opaqueView(),
                        ),
                )
        case .machineImag:
            manager.router?
                .presentModel(
                    NavPath
                        .view(
                            node: TextEditor(text: $composer.fileContent).opaqueView(),
                        ),
                )
        case .emoji:
            break
        }
    }
}
