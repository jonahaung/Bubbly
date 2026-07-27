//
//  DocumentPickerButton.swift
//  Conversation
//
//  Created by Aung Ko Min on 27/7/26.
//

import SwiftUI
import XUI
import Anima
import Services

struct DocumentPickerButton: View {

    let source = ChatComposer.Source.document
    @State private var isShowingPicker = false
    @State private var selectedFileNames: [URL] = []

    var body: some View {
        CustomButton {
            if selectedFileNames.isEmpty {
                isShowingPicker = true
            } else {
                Router.shared.presentModel(
                    .view(
                        node: DocumentViewer(urls: selectedFileNames)
                            .opaqueView()
                    )
                )
            }
        } label: {
            Image(systemName: selectedFileNames.isEmpty ? source.systemImageName : "\(selectedFileNames.count).circle")
                .resizable()
                .scaledToFit()
                .frame(square: 20)
                .changeEffect(.pulse(shape: .circle), value: selectedFileNames.count)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
                .symbolRenderingMode(.multicolor)
        }
        .accessibilityLabel(source.localizedName)
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: [.pdf, .plainText, .image],
            allowsMultipleSelection: true
        ) { result in
            handlePickerResult(result)
        }
    }

    private func handlePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedFileNames = []

            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }
                selectedFileNames.append(url)
            }
        case .failure(let error):
            log(error)
        }
    }
}
