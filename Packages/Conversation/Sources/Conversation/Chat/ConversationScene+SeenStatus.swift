//  ConversationScene+SeenStatus.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct SeenStatusOverlay: View {
    var body: some View {
        if let namespace {
            VStack {
                ForEach(manager.state.properties.seenMembers) { member in
                    if let contact = manager.contactsRepository?.contact(
                        for: member.uid
                    ) {
                        ProfilePhoto(
                            contact,
                            size: .custom(13),
                            tapAction: .none
                        )
                        .changeEffect(.pulse(shape: .capsule, style: .green, drawingMode: .stroke, count: 1), value: member.msgId)
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
            .animation(.easeInExponential, value: manager.state.properties.seenMembers)
            .geometryGroup()
            .equatable(by: manager.state.properties.seenMembers)
        }

    }

    @Environment(\.sharedNamespace) private var namespace
    @Environment(ChatManager.self) private var manager
}
