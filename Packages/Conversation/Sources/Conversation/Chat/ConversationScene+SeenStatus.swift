//  ConversationScene+SeenStatus.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct SeenStatusOverlay: View {
    
    @Environment(\.sharedNamespace) private var namespace
    @Environment(\.seenMembers) private var seenMembers
    @Environment(\.members) private var members
    
    var body: some View {
        if let namespace {
            ZStack {
                ForEach(seenMembers) { member in
                    if let contact = members.contact(for: member.uid) {
                        ProfilePhoto(
                            contact,
                            size: .custom(13),
                            tapAction: .none
                        )
                        .changeEffect(
                            .pulse(
                                shape: .circle,
                                style: .green,
                                drawingMode: .stroke,
                                count: 2
                            ),
                            value: member.msgId
                        )
                        .matchedGeometryEffect(
                            id: member.msgId,
                            in: namespace.value,
                            properties: .position,
                            anchor: .bottom,
                            isSource: false
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .flexible(.all)
            .animation(.bouncy, value: seenMembers)
            .geometryGroup()
            .equatable(by: seenMembers)
        }
    }
}
