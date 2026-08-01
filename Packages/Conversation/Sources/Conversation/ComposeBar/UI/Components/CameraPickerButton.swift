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

struct CameraPickerButton: View {

    private let source = ChatComposer.Source.camera
    @State private var isPresented = false
    @State private var capturedImage: UIImage?
    @State private var isSaving = false
    @State private var saveTask: Task<Void, Never>?
    private let imageWriter = CameraImageWriter()
    @Environment(ChatComposer.self) private var composer
    var selection: [URL] { composer.selection }
    
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
        .disabled(isSaving)
        .accessibilityLabel(source.localizedName)
        .accessibilityValue(isSaving ? "Saving" : "")
        .onDisappear(perform: cleanUp)
    }

    private func handleAction() {
        if selection.isEmpty == false {
            composer.lookUp = selection.first
        } else if let capturedImage {
            save(capturedImage)
        } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
            isPresented = true
        } else {
            
        }
    }

    private func handleSelection(_ image: UIImage) {
        saveTask?.cancel()
        let previousURLs = selection
        capturedImage = image
        Task {
            await imageWriter.removeFiles(at: previousURLs)
        }
    }

    private func save(_ image: UIImage) {
        saveTask?.cancel()
        isSaving = true
        saveTask = Task {
            var generatedURLs: [URL] = []
            do {
                let url = try await imageWriter.write(image)
                generatedURLs = [url]
                try Task.checkCancellation()
                capturedImage = nil
                composer.selection = [url]
                composer.lookUp = url
            } catch is CancellationError {
                await imageWriter.removeFiles(at: generatedURLs)
            } catch {
                await imageWriter.removeFiles(at: generatedURLs)
               
            }
            isSaving = false
            saveTask = nil
        }
    }
    private func cleanUp() {
        saveTask?.cancel()
        saveTask = nil
        capturedImage = nil
        let urls = selection
        
        Task {
            await imageWriter.removeFiles(at: urls)
        }
    }
}
