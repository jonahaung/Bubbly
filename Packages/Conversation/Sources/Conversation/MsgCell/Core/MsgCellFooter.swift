//  MsgCellFooter.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  MsgCellFooter.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//

import Core
import SwiftUI
import Services

struct MsgCellFooter: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    var body: some View {
        if state.isSelected { Footer(state: state) }
        if state.layout.showBottomSpacer { CellSpacer() }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state.isSelected == rhs.state.isSelected && lhs.state.layout.showBottomSpacer == rhs.state.layout.showBottomSpacer
    }
}

private struct Footer: View, @MainActor Equatable {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let receipts = state.outgoingStatus?.receipts, receipts.count > 1 {
                MessageReceiptDetails(state: state)
            } else {
                Text(footerText).font(
                    .system(size: UIFont.smallSystemFontSize, weight: .medium, design: .rounded)
                )
            }
        }
        .foregroundStyle(Color.tertiaryText)
        .padding(.horizontal, 35)
        .allowsHitTesting(false)
        .transition(.invisible())
        .equatable(by: state.outgoingStatus)
    }

    let state: MsgCellViewModel.State
    private var footerText: String {
        if state.isSender {
            state.msg.outgoingStatus?.localizedName ?? ""
        } else {
            state.date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    static func == (lhs: Footer, rhs: Footer) -> Bool { lhs.footerText == rhs.footerText }
}
