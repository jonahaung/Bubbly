//
//  MsgsScrollTargetBehavior.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/12/24.
//

import SwiftUI
import XUI
import Core

struct ScrollTargetData: Hashable, Sendable {
	let targetRect: CGRect
	let original: CGRect
	let contentSize: CGSize

	func offsetY(_ topInset: CGFloat) -> CGFloat {
		targetRect.minY - topInset
	}

	func fraction() -> CGFloat {
		let atTop = targetRect.midY < contentSize.height/2
		let fraction: CGFloat
		if atTop {
			fraction = targetRect.minY/contentSize.height
		} else {
			fraction = targetRect.maxY/contentSize.height
		}
		return fraction
	}
	func direction() -> ScrollDirection {
		guard targetRect.origin.y != original.origin.y else {
			return .none
		}
		return targetRect.origin.y < original.origin.y ? .isGoingUp : .isGoingDown
	}
}

struct MsgsScrollTargetBehavior: ScrollTargetBehavior {

	private let onTargetBehavior: ((direction: ScrollDirection, offsetY: CGFloat)) -> Bool

	init(
		_ onTargetBehavior: @escaping ((ScrollDirection, CGFloat)) -> Bool
	) {
		self.onTargetBehavior = onTargetBehavior
	}

	func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
		let data = ScrollTargetData(targetRect: target.rect, original: context.originalTarget.rect, contentSize: context.contentSize)
		let direction = data.direction()
	
		let fraction = data.fraction().rounded(toPlaces: 2)
		if fraction == 1 && onTargetBehavior((direction, target.rect.minY)) {
//			target.rect.origin.y = context.contentSize.height - context.containerSize.height - 5
		}
		if fraction == 0 && onTargetBehavior((direction, target.rect.minY)) {
//			target.rect.origin.y = -5
		}
	}
}
