//
//  CameraPickerButton.swift
//  Conversation
//
//  Created by Aung Ko Min on 1/8/26.
//

import Anima
import Services
import SwiftUI
import XUI
import Database

struct CameraPickerButton: View {

    private let source = ChatComposer.Source.camera
    @State private var isPresented = false
    @State private var saveTask: Task<Void, Never>?
    private let imageWriter = TemporaryFileWriter()
    @Environment(ChatComposer.self) private var composer

    var body: some View {
        CustomButton(action: handleAction) {
            Image(systemName: source.systemImageName)
                .resizable()
                .scaledToFit()
                .frame(square: 20)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
                .symbolRenderingMode(.multicolor)
        }
        .fullScreenCover(isPresented: $isPresented) {
            CameraPicker { pickedItem in
                switch pickedItem {
                case let pickedItem as ImageCameraPickerItem:
                    handleSelection(pickedItem.underlyingMediaType)
                case is MovieCameraPickerItem:
                    break
                default:
                    break
                }
            }
        }
        .onDisappear(perform: cleanUp)
    }

    private func handleAction() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            isPresented = true
        }
    }

    private func handleSelection(_ image: UIImage) {
        saveTask?.cancel()
        let previousURLs = composer.selection
        save(image)
        Task {
            await imageWriter.removeFiles(at: previousURLs)
        }
    }

    private func save(_ image: UIImage) {
        saveTask?.cancel()
        saveTask = Task {
            do {
                let attachment = try await AttachmentFactory.createImageAttachment(from: image)
                composer.state.attachments = [attachment]
            } catch {
                log(error)
            }
            //            var generatedURLs: [URL] = []
            //            guard let data = image.pngData() else { return }
            //            do {
            //                let url = try await imageWriter.write(data, pathExtension: "png")
            //                generatedURLs = [url]
            //                try Task.checkCancellation()
            //                composer.selection.append(url)
            //                let attachment = Attachment.init(uid: url.lastPathComponent, url: url.absoluteString, attachMentTypeRaw: Database.AttachMentType.imageUploading.rawValue, aspectRatio: image.aspectRatio)
            //                composer.state.attachments = [attachment]
            //            } catch is CancellationError {
            //                await imageWriter.removeFiles(at: generatedURLs)
            //            } catch {
            //                await imageWriter.removeFiles(at: generatedURLs)
            //
            //            }
            saveTask = nil
        }
    }
    private func cleanUp() {
        saveTask?.cancel()
        saveTask = nil
        Task {
            await imageWriter.removeFiles(at: composer.selection)
        }
    }
}
