// © 2026 Aung Ko Min
import Core
import Database
import Pow
import Services
import SwiftUI
extension MsgCell {
    struct IncomingAccessory: View, @MainActor Equatable {
        static func == (lhs: MsgCell.IncomingAccessory, rhs: MsgCell.IncomingAccessory) -> Bool {
            lhs.state.layout.showAvatar == rhs.state.layout.showAvatar
                && lhs.state.sender == rhs.state.sender
        }
        let state: MsgCellViewModel.State
        @Environment(\.msgCellActions) private var msgCellActions
        var body: some View {
            ZStack(alignment: .bottom) {
                if state.layout.showAvatar, let sender = state.sender {
                    ProfilePhoto(
                        sender, size: .custom(Spacing.md),
                        tapAction: .custom { msgCellActions?(.onTapAvatar(state.id)) }
                    ).equatable(by: sender.uid)
                }
            }.frame(width: Spacing.md + 4).geometryGroup()
        }
    }
}
