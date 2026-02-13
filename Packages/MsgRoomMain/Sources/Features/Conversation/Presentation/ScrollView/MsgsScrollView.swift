import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollView: View {
	let proxy: GeometryProxy
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.selectedMsg) private var selectedMsg
	@Environment(ConversationViewModel.self) private var viewModel

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			MsgsScrollViewLayout(
				manager.layoutManager,
				config: .init(
					manager.conversationConfig.lineSpacing,
					manager.conversationConfig.contentInsets,
					boundsWidth: proxy.insetAdjustedSize.width
				)
			) {
				if manager.presentation.showContactInfo {
					ConversationHeaderView()
				}
				ForEach(manager.models.ids, id: \.self) { id in
					if let viewModel = manager.models.cached(for: id) {
						MsgCell(viewModel: viewModel)
							.environment(viewModel)
							.id(viewModel.id)
							.onScrollVisibilityChange(threshold: 0.001) {
								[
									unowned viewModel
								] isVisible in
								viewModel.setVisibility(isVisible)
								if viewModel.layout.showTimeSeparator {
									manager.presentation.updateFloatingDate(viewModel.msg.date)
								}
							}
							.layoutValue(
								key: MsgLayoutValueKey.self,
								value: viewModel.msg.layoutValue()
							)
					}
				}
			}
		}
		.frame(width: proxy.insetAdjustedSize.width)
		.padding(
			.init(
				top: 0,
				leading: proxy.safeAreaInsets.leading,
				bottom: 0,
				trailing: proxy.safeAreaInsets
					.trailing
			)
		)
		.tint(Color.link.mix(with: Color.accentColor, by: 0.3))
		.transaction(value: viewModel.state) {
			let animation = manager.scrollController.defaultAnimation
			$0.animation = animation
			$0.disablesAnimations = animation == nil
			$0.addAnimationCompletion(criteria: .removed) {
				manager.scrollController.setDefaultAnimation(nil)
			}
		}
		.onScrollPhaseChange { oldPhase, newPhase, context in
			manager.scrollController.didChangeScrollPhase(oldPhase, newPhase, context)
		}
		.onScrollGeometryChange(
			for: VScrollGeometry.self,
			of: { .init($0) }
		) { oldValue, newValue in
			manager.scrollController
				.didChangeScrollGeometry(oldValue, newValue)
		}
		.scrollClipDisabled()
		.scrollDismissesKeyboard(.never)
		.scrollBounceBehavior(.always, axes: .vertical)
		.defaultScrollAnchor(.bottom, for: .sizeChanges)
		.scrollPosition(manager.scrollController.scrollPosition)
	}
}
