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
        @Environment(\.seenMembers) private var seenMembers
        @Environment(\.sharedNamespace) private var namespace

        var body: some View {
			ZStack(alignment: .bottom) {
				Color.primary.hidden()
				ForEach(Array(members().enumerated), id: \.element) { index, seenMember in
					if let contact = ContactsRepository.shared.contact(
						for: seenMember.uid
					) {
						ProfilePhoto(
							contact,
							size: .custom(10)
						).offset(y: index.cgFloat * -9)
					}
				}

            }
            .frame(width: 12)
			.flexible(.vertical)
			.padding(.trailing, 8)
			.allowsHitTesting(false)
			.equatable(by: members())
        }

        private func members() -> [SeenMember] {
			seenMembers.filter{ $0.msgId == viewModel.id }
//			seenMembers.removeDuplicates(by: { $0.msgId == $1.msgId || $0.uid == $1.uid }).filter {
//                $0.msgId == viewModel.id
//			}.removeDuplicates(by: \.uid)
        }
    }
}
