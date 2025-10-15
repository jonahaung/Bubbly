//
//  ChatScrollManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/10/24.
//  Refactored by ChatGPT
//

import Core
import Database
import ImageLoader
import SwiftUI
import XUI
import Combine
import Services

@MainActor
protocol ChatScrollManagerDelegate: AnyObject {
	var canLoadPrevious: Bool { get }
	var canLoadMore: Bool { get }
	var lastMsg: MsgSnapshot? { get }
	var firstMsg: MsgSnapshot? { get }
	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: ScrolledPosition)
	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: MsgSnapshot)
	func scrollManager(_ manager: ChatScrollManager, loadMore msg: MsgSnapshot)
}

@MainActor
@Observable
final class ChatScrollManager: ErrorPresenter {

	private(set) var scrollPosition = ScrollPosition()
	private(set) var scrolledPosition = ScrolledPosition.atBottom
	private(set) var bottomBarFrame = CGRect.zero
	private(set) var updatingState = ScrollViewUpdatingState.initial
	@ObservationIgnored private(set) var scrollPhase = ScrollPhase.idle
	@ObservationIgnored private(set) var isFirstResponder = false
	@ObservationIgnored private(set) var scrollDirection = ScrollDirection.none
	@ObservationIgnored private(set) var scrollGeometry: ScrollGeometry?
	@ObservationIgnored private(set) var visibleViewIDs = [String]()
	@ObservationIgnored private let scrollQueue = SerialTaskQueue()
	@ObservationIgnored private let scrollGeometryPublisher = PassthroughSubject<ScrollGeometry, Never>()
	@ObservationIgnored private let cancelBag = CancelBag()
	@ObservationIgnored let contentInsets: EdgeInsets = .init(
		top: ChatLayoutConstants.topBarHeight,
		leading: 4,
		bottom: ChatLayoutConstants.bottomBarHeight,
		trailing: 4
	)
	@ObservationIgnored let config: ConversationInitializer.Configuration

	// Latest known scroll container width (from ScrollGeometry.bounds.width).
	@ObservationIgnored private(set) var containerWidth: CGFloat = 0
	@ObservationIgnored weak var delegate: ChatScrollManagerDelegate?

	init(config: ConversationInitializer.Configuration) {
		self.config = config
		scrollGeometryPublisher
			.removeDuplicates()
			.debounce(for: 1, scheduler: DispatchQueue.main)
			.sink { [weak self] value in
				guard let self else { return }
				endScrollViewUpdates(for: value)
			}
			.store(in: cancelBag)
	}

	deinit {
		cancelBag.cancel()
		Log("Deinit")
	}
}
// Pagination
extension ChatScrollManager {
	private var canLoadPrevious: Bool {
		updatingState.isNotUpdating &&
		delegate?.canLoadPrevious == true
	}
	var canLoadMore: Bool {
		updatingState.isNotUpdating &&
		delegate?.canLoadMore == true
	}
	private func loadPreviousIfNeeded() {
		guard let msg = delegate?.firstMsg else { return }
		updateLoadingState(.insertingItems(.top))
		delegate?.scrollManager(self, loadPrevious: msg)
	}

	private func loadMoreIfNeeded() {
		guard let msg = delegate?.lastMsg else { return }
		updateLoadingState(.insertingItems(.bottom))
		delegate?.scrollManager(self, loadMore: msg)
	}

	private func loadMsgsIfNeeded(_ newValue: ScrollGeometry) {
		guard updatingState.isNotUpdating && !isFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.01 && canLoadPrevious {
				loadPreviousIfNeeded()
			}
		case .bottom:
			if location.fraction < 0.2 && canLoadMore {
				loadMoreIfNeeded()
			}
		}
	}
}
// Events
extension ChatScrollManager {

	func handleScrollPhaseChange(
		_ oldValue: ScrollPhase,
		_ newValue: ScrollPhase,
		_ context: ScrollPhaseChangeContext
	) {
		scrollPhase = newValue
		scrollGeometry = context.geometry
		if !newValue.isScrolling {
			scrolledPosition = context.geometry.scrolledPosition
		}
		// Update container width from the current geometry
		containerWidth = context.geometry.bounds.width
		scrollGeometryPublisher.send(context.geometry)
	}
	func handleScrollGeometryChange(_ oldValue: ScrollGeometry, _ newValue: ScrollGeometry) {
		// Track container width from geometry updates
		if containerWidth != newValue.bounds.width {
			containerWidth = newValue.bounds.width
		}
		if oldValue.contentSize.width != newValue.contentSize.width {
			return
		}
		if updatingState.isUpdating {
			guard oldValue.contentSize.height != newValue.contentSize.height else {
				return
			}
			switch updatingState {
			case .insertingItems(let edge):
				switch edge {
				case .top:
					adjustNeqwScrollPosition(newValue, newValue.adjustedOffsetY(from: oldValue, edge: .top))
					updateLoadingState(.notLoading)
				case .bottom:
					scrolledPosition = oldValue.scrolledPosition
					updateLoadingState(.notLoading)
				}
			case .removingItems(let edge):
				switch edge {
				case .top:
					adjustNeqwScrollPosition(newValue, newValue.adjustedOffsetY(from: oldValue, edge: .bottom))
					updateLoadingState(.notLoading)
				case .bottom:
					scrolledPosition = oldValue.scrolledPosition
					updateLoadingState(.notLoading)
				}
			case .resetting:
				adjustNeqwScrollPosition(newValue, newValue.bottomMostOffset)
				updateLoadingState(.notLoading)
			case .appendingItem:
				if oldValue.scrolledPosition.isAroundBottom {
					scroll(to: .offset(yPosition: newValue.bottomMostOffset, animated: true))
				}
				updateLoadingState(.notLoading)
			default:
				break
			}
		} else {
			loadMsgsIfNeeded(newValue)
		}

		func adjustNeqwScrollPosition(_ newValue: ScrollGeometry, _ offSetY: CGFloat) {
			var updatedGemotry = newValue
			updatedGemotry.contentOffset.y = offSetY
			scrollPosition = .init(y: updatedGemotry.contentOffset.y)
			scrolledPosition = updatedGemotry.scrolledPosition
		}
	}
	func handleVisibleIDsChange(_ ids: [String]) {
		visibleViewIDs = ids
	}
	func handleBottomBarFrameChange(_ oldValue: CGRect, _ newValue: CGRect) {
		guard oldValue != newValue else { return }
		if bottomBarFrame != newValue {
			bottomBarFrame = newValue
		}
		guard let scrollGeometry, newValue.maxY < oldValue.maxY else {
			isFirstResponder = false
			Haptics.play(.rigid, 0.5)
			return
		}
		isFirstResponder = true
		Haptics.play(.rigid, 0.5)
		guard scrolledPosition != .atBottom else { return }
		let targetY = scrollGeometry.contentOffset.y + (oldValue.maxY - newValue.maxY) + scrollGeometry.contentInsets.top
		scroll(to: .offset(yPosition: targetY, animated: false))
	}
}
// Scrolling
extension ChatScrollManager {
	func scroll(to item: ScrollPositionItem, duration: Double = 0.3) {
		switch item {
		case .offset(let yPosition, let animated):
			scrollQueue.addTask { [weak self] completion in
				guard let self = self else { return }
				self.performScroll(animated: animated, duration: duration) {
					self.scrollPosition.scrollTo(y: yPosition)
				} completion: {
					completion()
				}
			}

		case .id(value: let value, let anchor, animated: let animated):
			scrollQueue.addTask { [weak self] completion in
				guard let self = self else { return }
				self.performScroll(animated: animated, duration: duration) {
					self.scrollPosition.scrollTo(id: value, anchor: anchor)
				} completion: {
					completion()
				}
			}
		case .bottom(let animated):
			scrollQueue.addTask { [weak self] completion in
				guard let self = self else { return }
				self.performScroll(animated: animated, duration: duration) {
					self.scrollPosition.scrollTo(edge: .bottom)
				} completion: {
					completion()
				}
			}
		}
	}

	private func performScroll(
		animated: Bool,
		duration: Double = 0.4,
		_ action: () -> Void,
		completion: (@Sendable () -> Void)? = nil
	) {
		if animated {
			withAnimation(.interpolatingSpring(duration: duration)) {
				action()
			} completion: {
				completion?()
			}
		} else {
			action()
			DispatchQueue.delay {
				completion?()
			}

		}
	}
}
// Conditions
extension ChatScrollManager {
	func updateLoadingState(_ state: ScrollViewUpdatingState) {
		guard updatingState != .initial else { return }
		updatingState = state
	}

	func setHasViewUpdated() {
		updatingState = .notLoading
	}
	func endScrollViewUpdates(for newValue: ScrollGeometry) {
		// Make sure scrollView is not busy
		guard scrollGeometry == newValue && updatingState.isNotUpdating && scrollPhase == .idle && !isFirstResponder else {
			return
		}
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
	}
}

