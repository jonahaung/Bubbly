// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import Core
    import Database
    import Services
    import SwiftUI

    extension MsgCell {
        struct IncomingAccessory: View {
            @Environment(MsgCellViewModel.self) private var viewModel
            private var layout: MsgCellLayout {
                viewModel.state.layout
            }

            var body: some View {
                ZStack(alignment: .bottom) {
                    if layout.showAvatar, let sender = viewModel.state.sender {
                        ProfilePhoto(
                            sender,
                            size: .custom(ChatLayoutConstants.Cell.defaultSpacing),
                            tapAction: .none,
                        )
                        .equatable(by: sender.uid)
                    }
                }
                .frame(width: ChatLayoutConstants.Cell.defaultSpacing + 4)
                .padding(.leading, 8)
                .equatable(by: layout)
            }
        }
    }

#endif
