//
//  ChatDatasource.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

//
//  ChatDatasource.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

import Combine
import Core
import Database
import Foundation
import Services
import SwiftData
import XUI

@MainActor
protocol ChatDatasourceDelegate: AnyObject {
	func datasource(didInsert snapshot: Message)
	func datasource(didReceiveMsg snapshot: Message) async
	func datasource(didRemove snapshot: Message, animated: Bool)
	func datasource(didUpdate snapshot: Message, animated: Bool)
	func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async
	func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload)
	func datasource(didRecieveError error: Error) async
}

@MainActor
final class ChatDatasource {
	weak var delegate: ChatDatasourceDelegate?
	private let cancelBag = CancelBag()
	private let pageSize: Int
	private let msgStore = Store.shared.msgStore
	private let queue = SerialTaskQueue()

	init(
		config: ConversationInitializer.Configuration,
		delegate: ChatDatasourceDelegate? = nil
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
	}

	@concurrent
	func reset(conID: String) async throws -> [Message] {
		try await ConversationRepo.fetchMessages(
			conID: conID,
			limit: pageSize
		)
	}

	@concurrent
	func loadPrevious(before date: String, conID: String) async throws -> [Message] {
		var descriptor = await FetchDescriptor<PMsg>(
			predicate: makePredicate(
				conID: conID,
				date: date,
				comparison: .lessThan
			)
		)
		descriptor.sortBy = [.init(\.date, order: .reverse)]
		descriptor.fetchLimit = pageSize

		let snapshots = try await msgStore.fetch(descriptor)
		let ordered = Array(snapshots.reversed())
		return ordered
	}

	@concurrent
	func loadMore(after date: String, conID: String) async throws -> [Message] {
		var descriptor = await FetchDescriptor<PMsg>(
			predicate: makePredicate(
				conID: conID,
				date: date,
				comparison: .greaterThan
			)
		)
		descriptor.sortBy = [.init(\.date, order: .forward)]
		descriptor.fetchLimit = pageSize

		return try await msgStore.fetch(descriptor)
	}
}

// MARK: - Private Methods

extension ChatDatasource {
	fileprivate func performUpdate(_ data: AnyMsgData) async {
		switch data {
		case .newMsg(let rMsg):
			let msg = Message(rMsg)
			delegate?.datasource(didInsert: msg)
		//			delegate?.datasource(didReceiveMsg: msg)
		case .updatedMsg(let rMsg):
			delegate?.datasource(didUpdate: .init(rMsg), animated: false)
		case .reaction(let reaction):
			Log(reaction)
		case .typingStatus(let status):
			delegate?.datasource(didReceive: status)
		case .deleteMsg(let rMsg):
			do {
				try await msgStore.delete(uid: rMsg.uid)
				delegate?.datasource(didRemove: .init(rMsg), animated: true)
			} catch {
				await delegate?.datasource(didRecieveError: error)
			}
		case .seenStatus(let status):
			await delegate?.datasource(didReceive: status)
		}
	}

	private func makePredicate(
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
