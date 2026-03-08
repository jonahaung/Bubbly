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
//        @Environment(\.sharedNamespace) private var namespace

        var body: some View {
            VStack(alignment: .leading, spacing: 1) {
//				ForEach(members()) { seenMember in
//					if let contact = ContactsRepository.shared.contact(
//						for: seenMember.uid
//					) {
//						ProfilePhoto(
//							contact,
//							size: .custom(ChatLayoutConstants.Cell.defaultSpacing - 6)
//						)
//					}
//				}
            }
            .frame(width: ChatLayoutConstants.Cell.defaultSpacing - 4)
			.equatable(by: viewModel.id)
        }

//        private func members() -> [SeenMember] {
//            seenMembers.filter {
//                $0.msgId == viewModel.id
//			}.removeDuplicates(by: \.uid)
//        }
    }
}
