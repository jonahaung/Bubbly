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

final class ChatDatasource: @unchecked Sendable {

    weak var delegate: ChatDatasourceDelegate?
    private let cancelBag = CancelBag()
    private let pageSize: Int
    private let paginationPreload = PaginationPreloadState()
    private var topPreloadTask: Task<Void, Never>?
    private var bottomPreloadTask: Task<Void, Never>?
    private let queue = SerialTaskQueue()

    init(
        _ config: ConversationInitializer.Configuration,
        _ delegate: ChatDatasourceDelegate? = nil
    ) {
        pageSize = config.pageSize
        self.delegate = delegate

        NotificationCenter
            .default
            .publisher(for: .msgNoti(for: config.conID))
            .compactMap(\.anyMsgData)
            .receive(on: RunLoop.main)
            .sink { [weak self] data in
                guard let self else { return }
                queue.addTask { [weak self] completion in
                    guard let self else { return }
                    Task { @ChatActor in
                        await self.performUpdate(data)
                        try await Task.sleep(seconds: 0.5)
                        completion()
                    }
                }
            }
            .store(in: cancelBag)
    }

    deinit {
        cancelBag.cancel()
        topPreloadTask?.cancel()
        bottomPreloadTask?.cancel()
    }

    @concurrent
    func reset(conID: String) async throws -> [Message] {
        let messages = try await ConversationRepo.fetchMessages(
            conID: conID,
            limit: pageSize
        )
        await paginationPreload.clear()
        schedulePreloadAfter(messages: messages, conID: conID)
        return messages
    }

    @concurrent
    func loadPrevious(before date: String, conID: String) async throws -> [Message] {
        if let cached = await paginationPreload.consumeTop(before: date, conID: conID) {
            schedulePreloadAfter(messages: cached, conID: conID)
            return cached
        }

        let messages = try await fetchPrevious(before: date, conID: conID, limit: pageSize)
        schedulePreloadAfter(messages: messages, conID: conID)
        return messages
    }

    @concurrent
    func loadMore(after date: String, conID: String) async throws -> [Message] {
        if let cached = await paginationPreload.consumeBottom(after: date, conID: conID) {
            schedulePreloadAfter(messages: cached, conID: conID)
            return cached
        }

        let messages = try await fetchMore(after: date, conID: conID, limit: pageSize)
        schedulePreloadAfter(messages: messages, conID: conID)
        return messages
    }
}

// MARK: - Private Methods

extension ChatDatasource {
    private func schedulePreloadAfter(messages: [Message], conID: String) {
        guard !messages.isEmpty else { return }

        if let oldest = messages.first {
            let before = ServerTime(oldest.date).value
            topPreloadTask?.cancel()
            topPreloadTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let prefetched = try await self.fetchPrevious(
                        before: before,
                        conID: conID,
                        limit: self.pageSize
                    )
                    try Task.checkCancellation()
                    await self.paginationPreload.setTop(
                        .init(anchor: before, conID: conID, messages: prefetched)
                    )
                } catch {
                    await self.paginationPreload.clearTop(anchor: before, conID: conID)
                }
            }
        }

        if let newest = messages.last {
            let after = ServerTime(newest.date).value
            bottomPreloadTask?.cancel()
            bottomPreloadTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let prefetched = try await self.fetchMore(
                        after: after,
                        conID: conID,
                        limit: self.pageSize
                    )
                    try Task.checkCancellation()
                    await self.paginationPreload.setBottom(
                        .init(anchor: after, conID: conID, messages: prefetched)
                    )
                } catch {
                    await self.paginationPreload.clearBottom(anchor: after, conID: conID)
                }
            }
        }
    }

    private func fetchPrevious(before date: String, conID: String, limit: Int) async throws -> [Message] {
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

    private func fetchMore(after date: String, conID: String, limit: Int) async throws -> [Message] {
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

    private func performUpdate(_ data: AnyMsgData) async {
        switch data {
        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            await delegate?.datasource(didInsert: msg)
        case let .updatedMsg(rMsg):
            await delegate?.datasource(didUpdate: .init(rMsg), animated: false)
        case let .reaction(reaction):
            if let msg = try? await Store.shared.msgStore?.fetch(uid: reaction.msgID) {
                await delegate?.datasource(didUpdate: msg, animated: false)
            }
        case let .typingStatus(status):
            await delegate?.datasource(didReceive: status)
        case let .deleteMsg(rMsg):
            do {
                try await Store.shared.msgStore?.delete(uid: rMsg.uid)
                await delegate?.datasource(didRemove: .init(rMsg), animated: true)
            } catch {
                await delegate?.datasource(didRecieveError: error)
            }
        case let .seenStatus(status):
            await delegate?.datasource(didReceive: status)
        }
    }

    private func makePredicate(
        conID: String,
        date: String,
        comparison: PredicateExpressions.ComparisonOperator
    ) -> Predicate<
        PMsg
    > {
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

private actor PaginationPreloadState {
    struct Entry: Sendable {
        let anchor: String
        let conID: String
        let messages: [Message]
    }

    private var top: Entry?
    private var bottom: Entry?

    func consumeTop(before anchor: String, conID: String) -> [Message]? {
        guard let top, top.anchor == anchor, top.conID == conID else { return nil }
        self.top = nil
        return top.messages
    }

    func consumeBottom(after anchor: String, conID: String) -> [Message]? {
        guard let bottom, bottom.anchor == anchor, bottom.conID == conID else { return nil }
        self.bottom = nil
        return bottom.messages
    }

    func setTop(_ entry: Entry) {
        top = entry
    }

    func setBottom(_ entry: Entry) {
        bottom = entry
    }

    func clearTop(anchor: String, conID: String) {
        guard let top, top.anchor == anchor, top.conID == conID else { return }
        self.top = nil
    }

    func clearBottom(anchor: String, conID: String) {
        guard let bottom, bottom.anchor == anchor, bottom.conID == conID else { return }
        self.bottom = nil
    }

    func clear() {
        top = nil
        bottom = nil
    }
}
