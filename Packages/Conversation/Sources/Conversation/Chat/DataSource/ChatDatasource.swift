//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Core
import Database
import Foundation
import Services
import SwiftData
import XUI

protocol ChatDatasourceDelegate: AnyObject, Sendable {
    func datasource(didInsert snapshot: Message) async
    func datasource(didReceiveMsg snapshot: Message) async
    func datasource(didRemove snapshot: Message, animated: Bool) async
    func datasource(didUpdate snapshot: Message, animated: Bool) async
    func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async
    func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async
    func datasource(didRecieveError error: Error) async
}

actor ChatDatasource {

    @MainActor
    weak var delegate: ChatDatasourceDelegate?

    private let pageSize: Int
    private let boundaryState = PaginationBoundaryState()

    private let queue = SerialTaskQueue()
    private let cancelBag = CancelBag()

    // MARK: Init

    init(
        _ config: ConversationInitializer.Configuration
    ) {
        pageSize = config.pageSize
        NotificationCenter.default
            .publisher(for: .msgNoti(for: config.conID))
            .compactMap(\.anyMsgData)
            .sink { [weak self] data in
                guard let self else { return }

                self.queue.addTask { [weak self] completion in
                    guard let self else { return }

                    Task {
                        await self.performUpdate(data)
                        try? await Task.sleep(seconds: 0.5)
                        completion()
                    }
                }
            }
            .store(in: cancelBag)
    }

    deinit {
        cancelBag.cancel()
    }

    // MARK: Public State

    func canLoadOlder() async -> Bool {
        await boundaryState.canLoadOlder()
    }

    func canLoadNewer() async -> Bool {
        await boundaryState.canLoadNewer()
    }

    // MARK: Public API

    func reset(conID: String) async throws -> [Message] {

        let messages = try await ConversationRepo.fetchMessages(
            conID: conID,
            limit: pageSize
        )

        await boundaryState.reset()

        if messages.count < pageSize {
            await boundaryState.set(hasOlder: false)
        }

        return messages
    }

    func loadPrevious(
        before date: String,
        conID: String
    ) async throws -> [Message] {

        guard await boundaryState.canLoadOlder() else {
            return []
        }

        let messages = try await fetchPrevious(
            before: date,
            conID: conID,
            limit: pageSize
        )

        if messages.count < pageSize {
            await boundaryState.set(hasOlder: false)
        }

        return messages
    }

    func loadMore(
        after date: String,
        conID: String
    ) async throws -> [Message] {

        guard await boundaryState.canLoadNewer() else {
            return []
        }

        let messages = try await fetchMore(
            after: date,
            conID: conID,
            limit: pageSize
        )

        if messages.count < pageSize {
            await boundaryState.set(hasNewer: false)
        }

        return messages
    }
}

// MARK: - Private

private extension ChatDatasource {

    func fetchPrevious(
        before date: String,
        conID: String,
        limit: Int
    ) async throws -> [Message] {

        var descriptor = FetchDescriptor<PMsg>(
            predicate: makePredicate(
                conID: conID,
                date: date,
                comparison: .lessThan
            )
        )

        descriptor.sortBy = [.init(\.date, order: .reverse)]
        descriptor.fetchLimit = limit

        let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []

        return Array(snapshots.reversed())
    }

    func fetchMore(
        after date: String,
        conID: String,
        limit: Int
    ) async throws -> [Message] {

        var descriptor = FetchDescriptor<PMsg>(
            predicate: makePredicate(
                conID: conID,
                date: date,
                comparison: .greaterThan
            )
        )

        descriptor.sortBy = [.init(\.date, order: .forward)]
        descriptor.fetchLimit = limit

        return try await Store.shared.msgStore?.fetch(descriptor) ?? []
    }

    func performUpdate(_ data: AnyMsgData) async {

        switch data {

        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            await delegate?.datasource(didInsert: msg)
            if !msg.isSender {
                await delegate?.datasource(didReceiveMsg: msg)
            }

        case let .updatedMsg(rMsg):
            await delegate?.datasource(didUpdate: Message(rMsg), animated: false)

        case let .reaction(reaction):
            if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
                await delegate?.datasource(didUpdate: msg, animated: false)
            }

        case let .typingStatus(status):
            await delegate?.datasource(didReceive: status)

        case let .deleteMsg(rMsg):
            do {
                try await Store.shared.msgStore?.delete(uid: rMsg.uid)
                await delegate?.datasource(didRemove: Message(rMsg), animated: true)
            } catch {
                await delegate?.datasource(didRecieveError: error)
            }

        case let .seenStatus(status):
            await delegate?.datasource(didReceive: status)
        }
    }

    func makePredicate(
        conID: String,
        date: String,
        comparison: PredicateExpressions.ComparisonOperator
    ) -> Predicate<PMsg> {

        Predicate<PMsg> {
            PredicateExpressions.Conjunction(
                lhs: PredicateExpressions.build_Equal(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.conID
                    ),
                    rhs: PredicateExpressions.build_Arg(conID)
                ),
                rhs: PredicateExpressions.build_Comparison(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.date
                    ),
                    rhs: PredicateExpressions.build_Arg(date),
                    op: comparison
                )
            )
        }
    }
}

// MARK: - Boundary Actor

private actor PaginationBoundaryState {

    private var hasOlder = true
    private var hasNewer = true

    func set(hasOlder: Bool) {
        self.hasOlder = hasOlder
    }

    func set(hasNewer: Bool) {
        self.hasNewer = hasNewer
    }

    func canLoadOlder() -> Bool {
        hasOlder
    }

    func canLoadNewer() -> Bool {
        hasNewer
    }

    func reset() {
        hasOlder = true
        hasNewer = true
    }
}
