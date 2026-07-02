//  OutgoingAccessory.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI

// © 2026 Aung Ko Min
import Core
import SwiftUI
import Database
import Services

struct OutgoingAccessory: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    @Environment(\.sharedNamespace) private var namespace
    @Environment(\.conversationTheme) private var theme
    
    var body: some View {
        if let namespace {
            ZStack(alignment: .bottomLeading) {
                switch state.outgoingStatus?.aggregateStatus {
                case .delivered:
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10)
                        .fontWeight(.black)
                        .foregroundStyle(Color.tertiaryText)
                case .sent:
                    ZeroSizeView()
                case .sending:
                    Image(systemName: "progress.indicator")
                        .resizable()
                        .scaledToFit()
                        .frame(square: 10)
                        .symbolEffect(.rotate.clockwise.wholeSymbol, options: .repeat(.continuous).speed(10))
                case .partiallyFailed:
                    AsyncButton {
                        try await Socket.shared.send(.newMsg(rMsg: .init(state.msg)))
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(square: 13)
                            .foregroundStyle(.red)
                    }
                case .read:
                    Circle().fill(.clear)
                        .frame(square: 12)
                        .matchedGeometryEffect(
                            id: state.id, in: namespace.value, anchor: .bottom, isSource: true
                        )
                case .none:
                    ZeroSizeView()
                }
            }
            .symbolRenderingMode(.hierarchical)
            .frame(width: 13)
            .geometryGroup()
        }
    }

    static func == (lhs: OutgoingAccessory, rhs: OutgoingAccessory) -> Bool {
        lhs.state.outgoingStatus?.aggregateStatus == rhs.state.outgoingStatus?.aggregateStatus
    }
}
