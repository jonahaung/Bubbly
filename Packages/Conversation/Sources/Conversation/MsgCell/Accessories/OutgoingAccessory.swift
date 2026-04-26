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
    var body: some View {
        if let namespace {
            ZStack(alignment: .bottomLeading) {
                switch state.outgoingStatus?.aggregateStatus {
                case .delivered:
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(square: 8)
                case .sent:
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(square: 8)
                case .sending:
                    Image(systemName: "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(square: 8)
                case .partiallyFailed:
                    Circle()
                        .fill(.orange)
                        .frame(square: 8)
                        .matchedGeometryEffect(
                            id: state.id, in: namespace.value, anchor: .bottom, isSource: true
                        )
                case .read:
                    Circle().fill(.clear)
                        .frame(square: 12)
                        .matchedGeometryEffect(
                            id: state.id, in: namespace.value, anchor: .bottom, isSource: true
                        )
                case .initial:
                    ZeroSizeView()
                case .none:
                    ZeroSizeView()
                }
            }
            .fontWeight(.bold)
            .foregroundStyle(Color.blue.secondary)
            .frame(width: 13)
            .allowsHitTesting(false)
            .geometryGroup()
        }
    }
    
    static func == (lhs: OutgoingAccessory, rhs: OutgoingAccessory) -> Bool {
        lhs.state.outgoingStatus?.aggregateStatus == rhs.state.outgoingStatus?.aggregateStatus
    }
}
