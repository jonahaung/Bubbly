//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

public protocol SettingsReducer {
    func reduce(state: inout SettingsViewState, action: SettingsAction)
}

public struct SettingsReducerImpl: SettingsReducer {
    public init() {}

    public func reduce(state: inout SettingsViewState, action: SettingsAction) {
        switch action {
        case let .applyCurrentUser(value):
            state = SettingsViewState(
                currentUser: value,
                fontName: state.fontName,
                chatCellVerticalSpacing: state.chatCellVerticalSpacing,
                paginationPageSize: state.paginationPageSize,
                minutesForChatMsgGrouping: state.minutesForChatMsgGrouping
            )
        case let .setFontName(value):
            state = SettingsViewState(
                currentUser: state.currentUser,
                fontName: value,
                chatCellVerticalSpacing: state.chatCellVerticalSpacing,
                paginationPageSize: state.paginationPageSize,
                minutesForChatMsgGrouping: state.minutesForChatMsgGrouping
            )
        case let .setChatCellVerticalSpacing(value):
            state = SettingsViewState(
                currentUser: state.currentUser,
                fontName: state.fontName,
                chatCellVerticalSpacing: value,
                paginationPageSize: state.paginationPageSize,
                minutesForChatMsgGrouping: state.minutesForChatMsgGrouping
            )
        case let .setPaginationPageSize(value):
            state = SettingsViewState(
                currentUser: state.currentUser,
                fontName: state.fontName,
                chatCellVerticalSpacing: state.chatCellVerticalSpacing,
                paginationPageSize: value,
                minutesForChatMsgGrouping: state.minutesForChatMsgGrouping
            )
        case let .setMinutesForChatMsgGrouping(value):
            state = SettingsViewState(
                currentUser: state.currentUser,
                fontName: state.fontName,
                chatCellVerticalSpacing: state.chatCellVerticalSpacing,
                paginationPageSize: state.paginationPageSize,
                minutesForChatMsgGrouping: value
            )
        }
    }
}
