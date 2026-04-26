//  MsgCellHeader.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  MsgCellHeader.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//
import SwiftUI
import Services

struct MsgCellHeader: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    var body: some View {
        if state.layout.showTimeSeparator {
            TimeSeparator(dateString: state.dateStString)
        }
        if state.layout.showTopPadding { CellSpacer() }
        if state.isSelected { Header(headerText: headerText) }
    }

    private var headerText: String {
        if state.isSender {
            return state.date.formatted(date: .abbreviated, time: .shortened)
        } else {
            let name: String? = ContactsRepository.shared.contact(for: state.senderID)?.name
            return name ?? "Unknown"
        }
    }

    static func == (lhs: MsgCellHeader, rhs: MsgCellHeader) -> Bool {
        lhs.state.layout.showTimeSeparator == rhs.state.layout.showTimeSeparator
            && lhs.state.layout.showTopPadding == rhs.state.layout.showTopPadding
            && lhs.state.isSelected == rhs.state.isSelected
    }
}

private struct Header: View, Equatable {
    let headerText: String
    var body: some View {
        Text(headerText).font(
            .system(size: UIFont.smallSystemFontSize, weight: .medium, design: .rounded)
        ).foregroundStyle(Color.tertiaryText).padding(.horizontal, 35).allowsHitTesting(false)
            .transition(.push(from: .bottom)).geometryGroup().equatable(by: headerText)
    }
}
