// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct SeenStatusOverlay: View {
    var body: some View {
        ZStack {
            if let namespace {
                ForEach(manager.state.properties.seenMembers) { member in
                    if let contact = manager.contactsRepository?.contact(
                        for: member.uid,
                    ) {
                        ProfilePhoto(
                            contact,
                            size: .custom(13),
                            tapAction: .none,
                        )
                        .equatable(by: member.uid)
                        .matchedGeometryEffect(
                            id: member.msgId,
                            in: namespace.value,
                            properties: .position,
                            anchor: .bottomLeading,
                            isSource: false,
                        )
                    }
                }
            }
        }
        .flexible(.all)
        .animation(
            .interpolatingSpring,
            value: manager.state.properties.seenMembers,
        )
        .geometryGroup()
        .equatable(by: manager.state.properties.seenMembers)
    }

    // MARK: Private

    @Environment(\.sharedNamespace) private var namespace
    @Environment(ChatManager.self) private var manager
}
