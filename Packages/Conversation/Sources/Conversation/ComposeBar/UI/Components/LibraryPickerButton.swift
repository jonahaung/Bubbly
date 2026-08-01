import Anima
import PhotosUI
import SwiftUI
import XUI

struct LibraryPickerButton: View {

    private let source = ChatComposer.Source.liary

    @State private var isShowingPicker = false
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    private let fileWriter = LibraryPickerFileWriter()

    @Environment(ChatComposer.self) private var composer
    var selection: [URL] { composer.selection }

    var body: some View {
        CustomButton(action: handleAction) {
            Image(systemName: source.systemImageName)
                .resizable()
                .scaledToFit()
                .frame(square: 20)
                .changeEffect(.pulse(shape: .circle), value: selection.count)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
                .symbolRenderingMode(.multicolor)
        }
        .photosPicker(
            isPresented: $isShowingPicker,
            selection: $pickerSelection,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: pickerSelection, handlePickerSelection)
        .disabled(isLoading)
        .accessibilityLabel(source.localizedName)
        .accessibilityValue(isLoading ? "Loading" : "")
    }

    private func handleAction() {
        isShowingPicker = true
    }

    private func handlePickerSelection(
        _ previousItems: [PhotosPickerItem],
        _ items: [PhotosPickerItem]
    ) {
        guard items.isEmpty == false, items != previousItems else {
            composer.selection = []
            return
        }
        
        loadingTask?.cancel()
        isLoading = true
        loadingTask = Task {
            var loadedURLs: [URL] = []
            do {
                loadedURLs.reserveCapacity(items.count)
                for item in items {
                    try Task.checkCancellation()
                    guard
                        let data = try await item.loadTransferable(
                            type: Data.self
                        )
                    else {
                        throw CocoaError(.fileReadUnknown)
                    }
                    let contentType = item.supportedContentTypes.first {
                        $0.conforms(to: .image)
                    }
                    let url = try await fileWriter.write(
                        data,
                        pathExtension: contentType?.preferredFilenameExtension
                            ?? "jpg"
                    )
                    loadedURLs.append(url)
                }

                try Task.checkCancellation()
                let previousURLs = selection
                composer.selection = loadedURLs
                await fileWriter.removeFiles(at: previousURLs)
            } catch is CancellationError {
                await fileWriter.removeFiles(at: loadedURLs)
            } catch {
                await fileWriter.removeFiles(at: loadedURLs)
            }
            isLoading = false
            loadingTask = nil
        }
    }
}
