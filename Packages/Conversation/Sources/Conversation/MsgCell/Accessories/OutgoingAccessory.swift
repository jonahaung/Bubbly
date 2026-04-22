//  OutgoingAccessory.swift
//
//  Copyright © 2026 Aung Ko Min.
//

// © 2026 Aung Ko Min
import Core
import SwiftUI
import Database
import Services

struct OutgoingAccessory: View {
    let state: MsgCellViewModel.State
    var body: some View {
        if state.isSender, let namespace {
            ZStack(alignment: .bottomLeading) {
                Group {
                    switch state.deliveryStatus {
                    case .delivered:
                        Circle().fill(.blue)
                            .frame(square: 5)
                    case .sending:
                        Image(systemName: "progress.indicator")
                            .resizable()
                            .scaledToFit()
                            .frame(square: 12)
                            .symbolEffect(
                                .rotate, options: .repeat(.periodic), value: state.isVisible
                            )
                    case .sendingFailed:
                        Circle().fill(.red)
                            .frame(square: 8)
                    default: EmptyView()
                    }
                }
                .frame(square: 12).padding(.bottom, 2).fontWeight(.bold).imageScale(.small)
                .symbolRenderingMode(.monochrome)
            }.frame(width: 12).allowsHitTesting(false).matchedGeometryEffect(
                id: state.id, in: namespace.value, anchor: .leading, isSource: true
            )
            .geometryGroup().equatable(by: state.deliveryStatus)
        }
    }

    @Environment(\.sharedNamespace) private var namespace
}
