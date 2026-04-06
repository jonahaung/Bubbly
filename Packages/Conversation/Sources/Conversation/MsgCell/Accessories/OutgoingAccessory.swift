#if os(iOS)
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI

extension MsgCell {
    struct OutgoingAccessory: View {
        @Environment(MsgCellViewModel.self) private var viewModel
//        @Environment(\.seenMembers) private var seenMembers
        @Environment(\.sharedNamespace) private var namespace

        var body: some View {
			if let namespace {
				ZStack(alignment: .bottom) {
//					ForEach(Array(members().enumerated), id: \.element) { index, seenMember in
//						if let contact = ContactsRepository.shared.contact(
//							for: seenMember.uid
//						) {
//							ProfilePhoto(
//								contact,
//								size: .custom(12)
//							)
//							.offset(y: index.cgFloat * -9)
//							.matchedGeometryEffect(id: seenMember.uid, in: namespace.value)
//						}
//					}
				}
				.frame(width: 12)
				.padding(.trailing, 8)
				.allowsHitTesting(false)
				.matchedGeometryEffect(
					id: viewModel.id,
					in: namespace.value,
					anchor: .leading,
					isSource: true
				)
			}
        }

//        private func members() -> [SeenMember] {
//			seenMembers.filter{ $0.msgId == viewModel.id }
//        }
    }
}

#endif
