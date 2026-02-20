import Core
import Database
import Services
import SwiftUI

extension MsgCell {
	struct OutgoingAccessory: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.conversation) private var conversation
		@Environment(\.sharedNamespace) private var namespace

		var body: some View {
			if viewModel.isSender {
				VStack(alignment: .leading, spacing: 1) {
					let seenMembers = seenMembers()
					if !seenMembers.isEmpty {
						ForEach(seenMembers) { seenMember in
							if let contact = ContactsRepository.shared.contact(
								for: seenMember.uid
							) {
								ProfilePhoto(
									contact,
									size: .custom(ChatLayoutConstants.Cell.defaultSpacing - 6)
								)
//								.matchedGeometryEffect(
//									id: contact.uid,
//									in: namespace.unsafelyUnwrapped.value,
//									isSource: true
//								)
							}
						}
					}
				}
				.frame(width: ChatLayoutConstants.Cell.defaultSpacing - 4)
			}
		}

		private func seenMembers() -> [SeenMember] {
			conversation.properties.seenMembers.filter {
				$0.msgId == viewModel.id
			}
		}
	}
}
