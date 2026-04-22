//
//  MsgCellFooter.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//
import Services
import SwiftUI
struct MsgCellFooter: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    var body: some View { if state.isSelected { Footer(state: state) } }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.state.isSelected == rhs.state.isSelected }
}
private struct Footer: View, @MainActor Equatable {
    var body: some View {
        Text(footerText).font(
            .system(size: UIFont.smallSystemFontSize, weight: .medium, design: .rounded)
        ).foregroundStyle(Color.tertiaryText).padding(.horizontal, 35).allowsHitTesting(false)
            .transition(.asymmetric(insertion: .push(from: .top), removal: .opacity)).equatable(
                by: state.id)
    }
    let state: MsgCellViewModel.State
    private var footerText: String {
        if state.isSender {
            state.msg.deliveryStatus.localizedName
        } else {
            MsgTimeStringFormatter.string(for: state.date)
        }
    }
    static func == (lhs: Footer, rhs: Footer) -> Bool { lhs.footerText == rhs.footerText }
}
