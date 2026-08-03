//
//  MsgCellHeader.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/4/26.
//
import SwiftUI
import Services
import XUI

struct MsgCellHeader: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    @Environment(\.members) private var members
    var body: some View {
        if state.layout.showTimeSeparator {
            TimeSeparator(dateString: state.dateStString)
        }
        if state.isSelected { Header(headerText: headerText) }
    }

    private var headerText: String {
        if state.isSender {
            return state.date.formatted(date: .abbreviated, time: .shortened)
        } else {
            let name: String? = members.contact(for: state.senderID)?.name
            return name ?? "Unknown"
        }
    }

    static func == (lhs: MsgCellHeader, rhs: MsgCellHeader) -> Bool {
        lhs.state.layout.showTimeSeparator == rhs.state.layout.showTimeSeparator
            && lhs.state.isSelected == rhs.state.isSelected
    }
}

private struct Header: View, Equatable {
    let headerText: String
    var body: some View {
        Text(headerText)
            .font(Typography.system.caption2)
            .fontDesign(.rounded)
            .foregroundStyle(Color.secondaryText)
            .padding(.horizontal, 35)
            .allowsHitTesting(false)
            .transition(.invisible())
            .equatable(by: headerText)
    }
}
