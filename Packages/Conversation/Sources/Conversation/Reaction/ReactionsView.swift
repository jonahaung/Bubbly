// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

//
    //  ReactionsView.swift
    //  MsgRoomMain
//
    //  Created by Aung Ko Min on 5/11/25.
//
    import Database
    import SwiftUI

    public enum ReactionType: RawRepresentable, Sendable, Hashable, Identifiable, CaseIterable {
        public static var allCases: [ReactionType] {
            [.heart, .thumbUp, .thumbDown, .smile, .laugh, .sad]
        }

        public var id: String {
            rawValue
        }

        case heart
        case thumbUp
        case thumbDown
        case smile
        case laugh
        case sad
        case custom(String)

        public var rawValue: String {
            switch self {
            case .heart:
                "❤️"
            case .thumbUp:
                "👍"
            case .thumbDown:
                "👎"
            case .smile:
                "😊"
            case .laugh:
                "😂"
            case .sad:
                "😓"
            case let .custom(string):
                string
            }
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "❤️": self = .heart
            case "👍": self = .thumbUp
            case "👎": self = .thumbDown
            case "😊": self = .smile
            case "😂": self = .laugh
            case "😓": self = .sad
            default: self = .custom(rawValue)
            }
        }
    }

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
            static let inboundBubbleColor: Color = .init(red: 0.071, green: 0.078, blue: 0.086)
            static let reactionsBGColor: Color = .init(red: 0.055, green: 0.090, blue: 0.137)
        }

        struct ReactionState: Sendable, Hashable, Identifiable {
            var id: ReactionType {
                reaction
            }

            let reaction: ReactionType
            var count: Int
            var animationState: Bool = false

            init(reaction: ReactionType, count: Int = 0) {
                self.reaction = reaction
                self.count = count
            }

            var animationDuration: Double {
                switch reaction {
                case .heart,
                     .thumbUp:
                    ReactionsBar.Constants.animationDuration
                case .laugh,
                     .sad,
                     .thumbDown:
                    ReactionsBar.Constants.animationDuration
                default:
                    ReactionsBar.Constants.animationDuration
                }
            }
        }

        public let onReact: (ReactionType) -> Void

        @State private var allStates: [ReactionState] = ReactionType.allCases.map {
            ReactionState(reaction: $0)
        }

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
                damping: Constants.springDamping,
            ).delay(Constants.appearDelayIncrement / 2)) {
                for each in $allStates {
                    each.wrappedValue.count += 1
                }
            }
        }
    }

#endif
