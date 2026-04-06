
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
        let reactions: [Reaction]
        var body: some View {
            ReactionStackLayout {
                ForEach(
                    Array(reactions.reversed().enumerated()),
                    id: \.element
                ) { (index, reaction) in
                    Text(reaction.rawValue)
                        .font(.footnote)
                        .offset(x: index.cgFloat * -12)
						.transition(.movingParts.pop(.yellow))
                 }
            }
            .offset(y: -10)
            .padding(.horizontal, 8)
        }
    }
}
