//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollView: View {
	
    @Environment(\.sharedNamespace) private var namespace
    var manager: ChatViewManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            MsgsScrollViewLayout(manager.layoutManager) {
                if manager.presentation.state.showContactInfo {
                    ConversationHeaderView()
                }
                ForEach(manager.models.renderedModels, id: \.id) { viewModel in
                    MsgCell(viewModel: viewModel)
                        .environment(viewModel)
                        .id(viewModel.id)
                        .layoutValue(
                            key: MsgLayoutValueKey.self,
                            value: viewModel.layoutValue
                        )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .scrollTargetLayout()
        }
        .frame(width: manager.layoutManager.boundsWidth)
        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize))
        .tint(Color.link.mix(with: Color.accentColor, by: 0.3))
        .animation(.interactiveSpring, value: manager.layoutManager.selectedMsg)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            guard oldPhase != newPhase else { return }
            manager.send(.onScrollPhaseChange(oldPhase, newPhase, context: context))
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.5) {
            manager.send(.onScrollTargetVisibilityChange($0))
        }
        .onScrollGeometryChange(
            for: VScrollGeometry.self,
            of: { .init($0) }
        ) { oldValue, newValue in
            guard oldValue != newValue else { return }
            manager.send(.onScrollGeometryChange(oldValue, newValue))
        }
        .scrollDismissesKeyboard(.never)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .equatable(by: manager.state)
        .defaultScrollAnchor(
            manager.presentation.state.bottomAccessory == .scrollDownButton ? .top : .bottom,
            for: .sizeChanges
        )
        .scrollPosition(manager.scrollController.scrollPositionBindable, anchor: .none)
    }
}

struct VelocityAwareChatScrollBehavior: ScrollTargetBehavior {

    var onTarget: (CGFloat) -> Void

    init(_ onTarget: @escaping (CGFloat) -> Void) {
        self.onTarget = onTarget
    }

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {

        let horizontal = context.axes.contains(.horizontal)
        let vertical = context.axes.contains(.vertical)

        guard horizontal || vertical else { return }

        let dy = abs(context.originalTarget.rect.minY - target.rect.minY)
        if dy != 0 {
            onTarget(target.rect.origin.y)
            //			if target.rect.origin.y < 200 {
            //				target.rect.origin.y = 200
            //			}
        }

//
        //		let isHorizontal = horizontal && dx > dy
//
        //		let pageSize = isHorizontal
        //		? context.containerSize.width
        //		: context.containerSize.height
//
        //		let contentSize = isHorizontal
        //		? context.contentSize.width
        //		: context.contentSize.height
//
        //		guard contentSize > pageSize else {
        //			if isHorizontal {
        //				target.rect.origin.x = 0
        //			} else {
        //				target.rect.origin.y = 0
        //			}
        //			return
        //		}
//
        //		let maxOffset = contentSize - pageSize
//
        //		let originalOffset = isHorizontal
        //		? context.originalTarget.rect.minX
        //		: context.originalTarget.rect.minY
//
        //		let proposedOffset = isHorizontal
        //		? target.rect.minX
        //		: target.rect.minY
//
        //		let velocity = isHorizontal
        //		? context.velocity.dx
        //		: context.velocity.dy
//
        //		let dragDelta = proposedOffset - originalOffset
        //		let threshold = pageSize * thresholdRatio
//
        //		var page = originalOffset / pageSize
//
        //		// Flick
        //		if abs(velocity) > velocityThreshold {
        //			page += velocity > 0 ? 1 : -1
        //		}
        //		// Slow drag
        //		else if abs(dragDelta) > threshold {
        //			page += dragDelta > 0 ? 1 : -1
        //		}
        //		else {
        //			page = round(page)
        //		}
//
        //		let destination = (round(page) * pageSize)
        //			.clamped(to: 0...maxOffset)
//
        //		if isHorizontal {
        //			target.rect.origin.x = destination
        //		} else {
        //			target.rect.origin.y = destination
        //		}
    }
}

extension Comparable {

    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
