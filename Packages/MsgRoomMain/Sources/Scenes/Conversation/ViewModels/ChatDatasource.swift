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

// MARK: - Delegate Protocol

protocol ChatDatasourceDelegate: AnyObject {
	func datasource(didInsert snapshot: MsgSnapshot) async
	func datasource(didReceiveMsg snapshot: MsgSnapshot) async
	func datasource(didRemove snapshot: MsgSnapshot, animated: Bool) async
	func datasource(didUpdate snapshot: MsgSnapshot, animated: Bool) async
	func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async
	func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async
	func datasource(didRecieveError: Error) async
}

// MARK: - Main Actor

actor ChatDatasource {

	// MARK: - Properties

	nonisolated(unsafe) weak var delegate: ChatDatasourceDelegate?

	private let cancelBag = CancelBag()
	private let socketQueue = AsyncSerialQueue()
	private let configuration: ConversationInitializer.Configuration

	// MARK: - Initialization

	init(config: ConversationInitializer.Configuration, delegate: ChatDatasourceDelegate? = nil) {
		self.configuration = config
		self.delegate = delegate
	}

	// MARK: - Public Methods

	@concurrent
	func reset(conID: String) async throws -> [MsgSnapshot] {
		try await ConversationRepo.fetchMessages(
			conID: conID,
			limit: configuration.pageSize
		)
	}

	func onViewAppear() {
		setupNotificationObserver()
	}
	@concurrent
	func loadPrevious(before date: String, conID: String) async throws -> [MsgSnapshot] {
		var descriptor = FetchDescriptor<PMsg>(
			predicate: Self.makePredicate(
				conID: conID,
				date: date,
				comparison: .lessThan
			)
		)
		descriptor.sortBy = [.init(\.date, order: .reverse)]
		descriptor.fetchLimit = configuration.pageSize-10

		let snapshots = try await Store.shared.msgStore.fetch(descriptor)
		let ordered = Array(snapshots.reversed())
		return ordered
	}

	@concurrent
	func loadMore(after date: String, conID: String) async throws -> [MsgSnapshot] {
		var descriptor = FetchDescriptor<PMsg>(
			predicate: Self.makePredicate(
				conID: conID,
				date: date,
				comparison: .greaterThan
			)
		)
		descriptor.sortBy = [.init(\.date, order: .forward)]
		descriptor.fetchLimit = configuration.pageSize-10

		return try await Store.shared.msgStore.fetch(descriptor)
	}
}

// MARK: - Private Methods

private extension ChatDatasource {

	func setupNotificationObserver() {
		NotificationCenter.default
			.publisher(for: .msgNoti(for: configuration.conID))
			.compactMap { $0.anyMsgData }
			.sink { [weak self] data in
				guard let self else { return }
				socketQueue.addOperation {
					try await self.performUpdate(data)
				}
			}
			.store(in: cancelBag)
	}

	func performUpdate(_ data: AnyMsgData) async throws {
		switch data {
		case .newMsg(let rMsg):
			let msg = MsgSnapshot(rMsg)
			await delegate?.datasource(didInsert: msg)
			await delegate?.datasource(didReceiveMsg: msg)

		case .updatedMsg(let rMsg):
			await delegate?.datasource(didUpdate: .init(rMsg), animated: false)

		case .reaction(let reaction):
			Log(reaction)

		case .typingStatus(let status):
			await delegate?.datasource(didReceive: status)

		case .deleteMsg(let rMsg):
			try await Store.shared.msgStore.delete(uid: rMsg.uid)
			await delegate?.datasource(didRemove: .init(rMsg), animated: true)
			
		case .seenStatus(let status):
			await delegate?.datasource(didReceive: status)
		}
	}

	static func makePredicate(
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
