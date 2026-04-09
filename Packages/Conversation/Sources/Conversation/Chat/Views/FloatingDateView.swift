// © 2026 Aung Ko Min

//
//  FloatingDateView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/4/25.
//
import Core
import SwiftUI
import XUI

struct FloatingDateView: View {
    @Environment(ChatManager.self) private var manager

    var body: some View {
        if let dateText = manager.presentation.state.dateText {
            Text(dateText)
                .font(.footnote.bold())
                .lineHeight(.normal)
                .lineSpacing(0)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.appPrimary, in: .capsule)
        }
    }
}
