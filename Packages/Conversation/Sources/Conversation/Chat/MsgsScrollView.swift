import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollView: View {
	let accessoryFrame: CGRect
	@Environment(\.selectedMsg) private var selectedMsg
	var manager: ChatViewManager
	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				manager.layoutManager,
				config: .init(
					manager.conversationConfig.lineSpacing,
					manager.conversationConfig.contentInsets,
					boundsWidth: accessoryFrame.width
				)
			) {
				if manager.presentation.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(manager.models.renderedModels, id: \.id) { viewModel in
					MsgCell(viewModel: viewModel)
						.environment(viewModel)
						.id(viewModel.id)
						.layoutValue(
							key: MsgLayoutValueKey.self,
							value: viewModel.msg.layoutValue()
						)
				}
			}.scrollTargetLayout()
		}
		.frame(width: accessoryFrame.width)
		.padding(.leading, accessoryFrame.minX)
		.tint(Color.link.mix(with: Color.accentColor, by: 0.3))
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.send(.onScrollPhaseChange(oldPhase, newPhase, context: context))
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: { .init($0) }
		) { oldValue, newValue in
			manager.send(.onScrollGeometryChange(oldValue, newValue))
		}
		.onScrollTargetVisibilityChange(idType: String.self, threshold: 0.1) {
			manager.send(.onScrollTargetVisibilityChange($0))
		}
		.scrollDismissesKeyboard(.never)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.equatable(by: manager.layoutSignature)
		.scrollPosition(manager.scrollController.scrollPosition, anchor: .none)
	}
}
