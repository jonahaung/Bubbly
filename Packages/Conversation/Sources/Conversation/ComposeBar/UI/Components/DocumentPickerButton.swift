//
//  DocumentPickerButton.swift
//  Conversation
//
//  Created by Aung Ko Min on 27/7/26.
//

import Anima
import Services
import SwiftUI
import XUI

struct DocumentPickerButton: View {

    let source = ChatComposer.Source.document
    @State private var isPresented = false
    @Environment(ChatComposer.self) private var composer
    var selection: [URL] { composer.selection }

    var body: some View {
        CustomButton {
            isPresented = true
        } label: {
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
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.pdf, .plainText, .image],
            allowsMultipleSelection: true
        ) { result in
            handlePickerResult(result)
        }
        .accessibilityLabel(source.localizedName)
    }

    private func handlePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            composer.selection = []
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }
                composer.selection.append(url)
            }
        case .failure(let error):
            log(error)
        }
    }
}
