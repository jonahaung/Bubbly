//
//  MsgRoomEntryPoint.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import Core
import Database
import FirebaseAuth
import Services
import SwiftUI
import XUI

private struct MsgRoomEntryPointModifier: ViewModifier, ErrorPresenter {
    @LazyState private var currentUser: CurrentUser

    init(_ user: User) {
        _currentUser = .init(wrappedValue: .init(user))
    }

    func body(content: Content) -> some View {
        content
            .environment(\.currentUser, currentUser.model)
            .environment(ContactStore.shared)
            .environment(\.sendChatRoomAction) { data in
                Task {
                    do {
                        let conversation = try await ConversationRepo.getOrCreate(
                            for: data.conID, refetch: false
                        )
                        try await Socket.shared
                            .send(data, conversation: conversation)
                    } catch {
                        Log(error)
                    }
                }
            }
            .task {
                do {
                    currentUser.start()
                    try await ContactStore.shared.fetchData()
                } catch {
                    Log(error)
                }
            }
    }
}

public extension View {
    func msgRoomEntryPoint(_ user: User) -> some View {
        ModifiedContent(
            content: self,
            modifier: MsgRoomEntryPointModifier(user)
        )
    }
}
