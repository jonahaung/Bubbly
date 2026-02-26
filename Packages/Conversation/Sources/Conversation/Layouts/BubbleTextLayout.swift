import SwiftUI

import SwiftUI

public struct SingleSubviewLayout: Layout {

	public struct Cache {
		var proposal: ProposedViewSize?
		var size: CGSize = .zero
	}

	public init() {}

	public func makeCache(subviews: Subviews) -> Cache {
		Cache()
	}

	public func updateCache(_ cache: inout Cache, subviews: Subviews) {
		// No-op: nothing structural changes
	}

	public func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGSize {

		guard let subview = subviews.first else { return .zero }

		// If proposal matches previous, return cached size
		if cache.proposal == proposal {
			return cache.size
		}

		let measured = subview.sizeThatFits(proposal)
		cache.proposal = proposal
		cache.size = measured
		return measured
	}

	public func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		subviews.forEach { each in
			each.place(
				at: bounds.origin,
				proposal: proposal
			)
		}
	}
}
