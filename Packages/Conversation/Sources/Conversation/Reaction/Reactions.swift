//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Reactions: View {
        @Environment(MsgCellViewModel.self) private var viewModel
        @Environment(\.viewIsVisible) private var viewIsVisible: Bool

        var body: some View {
            ZStack {
                ForEach(
                    Array(viewModel.msg.reactions.reversed().enumerated()),
                    id: \.offset
                ) { pair in
                    let index = pair.offset
                    let reaction = pair.element

                    Text(reaction.rawValue)
                        .font(.footnote)
                        .offset(x: index.cgFloat * -12)
                        .phaseAnimator(
                            [false, true],
                            trigger: viewModel.animationTrigger
                        ) { content, phase in
                            content
                                .modifier(
                                    ReactionAnimationModifier(
                                        reaction: .init(rawValue: reaction.rawValue)!,
                                        isActive: phase
                                    )
                                )
                        } animation: { _ in
                            .bouncy(
                                duration: ReactionsBar
                                    .ReactionState(
                                        reaction: .init(rawValue: reaction.rawValue)!
                                    ).animationDuration,
                                extraBounce: ReactionsBar.Constants
                                    .extraBounce
                            )
                        }
                }
            }
            .offset(y: -10)
            .padding(.horizontal, 8)
        }
    }
}
