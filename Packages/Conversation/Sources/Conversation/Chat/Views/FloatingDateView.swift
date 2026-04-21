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
    private var dateString: String? { manager.presentation.state.dateText }
    var body: some View {
        if let dateString {
            VStack {
                Text(dateString)
                    .font(.system(size: UIFont.smallSystemFontSize, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.container.opacity(0.8), in: RoundedRectangle(cornerRadius: Radius.md))
            .geometryGroup()
            .equatable(by: dateString)
        }
    }
}
