//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import FirebaseCore
import Foundation
@testable import MsgRoomMain
@testable import Services
import Testing

@MainActor
struct ConversationViewModelIntentTests {
    @Test
    func initialStateUsesPrefetchedData() async {
        configureFirebaseIfNeeded()
        let fixture = makeFixture()
        let sut = ConversationViewModel(fixture.prefetchedData)
        await waitForTasks()
        #expect(sut.state.messages.map(\.uid) == fixture.messages.map(\.uid))
        #expect(sut.state.conversation.uid == fixture.conversation.uid)
        #expect(sut.state.isLoading == false)
        #expect(sut.state.error == nil)
        #expect(sut.state.shouldDismiss == false)
    }

    @Test
    func tapMessageIntentSelectsMessage() async {
        configureFirebaseIfNeeded()
        let fixture = makeFixture()
        let sut = ConversationViewModel(fixture.prefetchedData)
        sut.send(.tapMessage("m2"))
        await waitForTasks()
        #expect(sut.state.selectedMsg?.id == "m2")
    }

    @Test
    func focusMsgBubbleIntentUpdatesOverlayState() async {
        configureFirebaseIfNeeded()
        let fixture = makeFixture()
        let sut = ConversationViewModel(fixture.prefetchedData)
        let item = ChatOverlayView.Item(id: "m1", frame: .init(x: 0, y: 0, width: 40, height: 40))
        sut.send(.focusMsgBubble(item))
        await waitForTasks()
        #expect(sut.state.overlayItem?.id == item.id)
        sut.send(.focusMsgBubble(nil))
        await waitForTasks()
        #expect(sut.state.overlayItem == nil)
    }

    @Test
    func closeConversationIntentSetsDismissFlag() async {
        configureFirebaseIfNeeded()
        let fixture = makeFixture()
        let sut = ConversationViewModel(fixture.prefetchedData)
        sut.send(.closeConversation)
        await waitForTasks(iterations: 80)
        #expect(sut.state.shouldDismiss)
    }

    private func makeFixture() -> (
        conversation: Conversation,
        messages: [Message],
        prefetchedData: ConversationInitializer.PrefetchedData
    ) {
        let conID = "con-1"
        let conversation = Conversation(
            kind: .contact(.empty),
            uid: conID,
            properties: .init(uid: conID)
        )
        let messages = [
            Message(
                uid: "m1",
                senderID: "user-1",
                conID: conID,
                text: "Hello",
                date: Date(timeIntervalSince1970: 1),
                incomingStatus: .none,
                outgoingStatus: [:],
                attachments: [],
                reactions: []
            ),
            Message(
                uid: "m2",
                senderID: "user-2",
                conID: conID,
                text: "Hi",
                date: Date(timeIntervalSince1970: 2),
                incomingStatus: .none,
                outgoingStatus: [:],
                attachments: [],
                reactions: []
            )
        ]
        let configuration = ConversationInitializer.Configuration(
            conID: conID,
            pageSize: 20,
            lineSpacing: 0,
            lastMsgID: messages.last?.uid,
            firstMsgID: messages.first?.uid,
            totalMsgsCount: messages.count,
            canPaginate: false
        )
        let prefetchedData = ConversationInitializer.PrefetchedData(
            conversation: conversation,
            msgs: messages,
            configuration: configuration
        )
        return (conversation, messages, prefetchedData)
    }

    private func waitForTasks(iterations: Int = 40) async {
        for _ in 0..<iterations {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    private func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else {
            return
        }
        let options = FirebaseOptions(
            googleAppID: "1:1234567890:ios:test",
            gcmSenderID: "1234567890"
        )
        options.apiKey = "test-api-key"
        options.projectID = "test-project-id"
        FirebaseApp.configure(options: options)
    }
}
