//
//  ReactionsView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 5/11/25.
//
import SwiftUI

public struct ReactionsView: View {
    enum Constants {
        static let animationDuration: Double = 0.4
        static let extraBounce: Double = 0.4
        static let appearDelayIncrement: Double = 0.1
        static let springStiffness: Double = 170
        static let springDamping: Double = 8
        static let itemSpacing: CGFloat = 1
        static let scaleMultiplier: Double = 1.5
        static let floatOffset: CGFloat = -30
        static let rotationAngle: Double = 45
        static let inboundBubbleColor = Color(red: 0.071, green: 0.078, blue: 0.086)
        static let reactionsBGColor = Color(red: 0.055, green: 0.090, blue: 0.137)
    }

    struct ReactionState: Sendable, Hashable, Identifiable {
        let id: ReactionType
        var count: Int
        var animationState: Bool = false

        init(type: ReactionType, count: Int = 0) {
            id = type
            self.count = count
        }
    }

    @State private var reactions: [ReactionState] = ReactionType.allCases.map {
        ReactionState(
            type: $0
        )
    }

    @State private var isVisible = false

    public init() {}

    public var body: some View {
        HStack(spacing: Constants.itemSpacing) {
            ForEach($reactions) { $reaction in
                ReactionButton(reactionState: $reaction, isVisible: isVisible)
            }
        }
		.padding()
		.background(Color.systemBackground.opacity(0.00001))
		.foregroundStyle(Color.accentColor)
        .onAppear {
            animateAppearance()
        }
    }

    private func animateAppearance() {
        withAnimation(.interpolatingSpring(
            stiffness: Constants.springStiffness,
            damping: Constants.springDamping
        ).delay(Constants.appearDelayIncrement / 2)) {
            isVisible = true
        }
    }
}
