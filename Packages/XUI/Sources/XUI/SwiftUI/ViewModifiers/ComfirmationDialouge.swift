//
//  ComfirmationDialouge.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import SwiftUI

private struct XDialogModifier<DialogContent: View>: ViewModifier {
    let title: String
    let message: String
    @ViewBuilder var dialogContent: () -> DialogContent
    @State private var isShown = false

    func body(content: Content) -> some View {
        Button {
            isShown = true
        } label: {
            content
        }
        .confirmationDialog(.init(title), isPresented: $isShown, titleVisibility: .visible, actions: {
            dialogContent()
        }, message: {
            Text(.init(message))
        })
    }
}

public extension View {
    func _comfirmationDialouge(_ title: String = "Attention", message: String = "", @ViewBuilder _ content: @escaping () -> some View) -> some View {
        ModifiedContent(content: self, modifier: XDialogModifier(title: title, message: message, dialogContent: content))
    }
}
