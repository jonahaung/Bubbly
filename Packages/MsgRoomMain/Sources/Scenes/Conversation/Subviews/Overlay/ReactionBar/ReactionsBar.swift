//
//  ReactionsView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//
import SwiftUI
import Database

public struct ReactionsBar: View {
	enum Constants {
		static let animationDuration: Double = 0.5
		static let extraBounce: Double = 0.4
		static let appearDelayIncrement: Double = 0.1
		static let springStiffness: Double = 170
		static let springDamping: Double = 8
		static let itemSpacing: CGFloat = 0
		static let scaleMultiplier: Double = 1.8
		static let floatOffset: CGFloat = -30
		static let rotationAngle: Double = 45
		static let inboundBubbleColor = Color(red: 0.071, green: 0.078, blue: 0.086)
		static let reactionsBGColor = Color(red: 0.055, green: 0.090, blue: 0.137)
	}

	struct ReactionState: Sendable, Hashable, Identifiable {
		var id: String { reaction }
		let reaction: String
		var count: Int
		var animationState: Bool = false

		init(reaction: String, count: Int = 0) {
			self.reaction = reaction
			self.count = count
		}

		var animationDuration: Double {
			switch reaction {
			case "❤️", "👍":
				ReactionsBar.Constants.animationDuration
			case "👎", "😂", "😓":
				ReactionsBar.Constants.animationDuration
			default:
				ReactionsBar.Constants.animationDuration
			}
		}
	}

	public let onReact: (String) -> Void

	@State private var allStates: [ReactionState] = Reaction.allCases.map {
		ReactionState(reaction: $0)
	}

	@State private var isVisible = false

	public var body: some View {
		HStack(spacing: Constants.itemSpacing) {
			ForEach($allStates) { $reaction in
				ReactionButton(reactionState: $reaction, onReact: onReact)
			}
		}
		.font(.system(size: 20, design: .monospaced))
		.onAppear {
			animateAppearance()
		}
	}

	private func animateAppearance() {
		withAnimation(.interpolatingSpring(
			stiffness: Constants.springStiffness,
			damping: Constants.springDamping
		).delay(Constants.appearDelayIncrement / 2)) {
			$allStates.forEach { each in
				each.wrappedValue.count += 1
			}
		}
	}
}
