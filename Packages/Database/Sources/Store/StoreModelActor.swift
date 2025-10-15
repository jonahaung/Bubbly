//
//  DbCollection.swift
//  Database
//
//  Created by Aung Ko Min on 12/7/25.
//

import Foundation
import SwiftData

public actor StoreModelActor<T>: ModelActor where T: PersistentModel & CollectionDocument & SendableDocument, T.SendableType: Sendable, T.UID == String, T.SendableType.UID == String {

	public nonisolated let modelExecutor: any SwiftData.ModelExecutor
	public nonisolated let modelContainer: SwiftData.ModelContainer

	private var context: ModelContext { modelExecutor.modelContext }
	private var fetchedLast: T?

	public init(modelContainer: SwiftData.ModelContainer, modelExecutor: ModelExecutor) {
		self.modelExecutor = modelExecutor
		self.modelContainer = modelContainer
	}

	public func insert(_ data: T.SendableType) throws {
		guard try fetchCount(uid: data.uid) == 0 else { return }
		context.insert(T(from: data))
		try context.save()
	}

	public func fetch(id: PersistentIdentifier) -> T.SendableType? {
		return self[id, as: T.self]?.toSendable()
	}

	public func fetch(uid: String) throws -> T.SendableType? {
		if fetchedLast?.uid == uid { return fetchedLast?.toSendable() }
		let descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.uid == uid })
		let dataArr = try context.fetch(descriptor)
		fetchedLast = dataArr.first
		return fetchedLast?.toSendable()
	}

	public func isExisted(uid: String) throws -> Bool {
		return try fetchCount(uid: uid) > 0
	}

	public func fetchCount(uid: String) throws -> Int {
		let descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.uid == uid })
		return try context.fetchCount(descriptor)
	}

	public func fetchCount(descriptor: FetchDescriptor<T>) throws -> Int {
		return try context.fetchCount(descriptor)
	}

	public func delete(id: PersistentIdentifier) throws {
		guard let data = self[id, as: T.self] else { return }
		fetchedLast = nil
		context.delete(data)
		try context.save()
	}

	public func delete(uid: String) throws {
		guard let data = try get(uid: uid) else { return }
		fetchedLast = nil
		context.delete(data)
		try context.save()
	}

	public func updateAndSave<Result: Sendable>(uid: String, _ updateFn: sending (inout T) -> Result) throws -> Result? {
		guard var data = try get(uid: uid) else { return nil }
		let result = updateFn(&data)
		try context.save()
		return result
	}

	var saveTask: Task<Void, Never>?

	public func saveDebounced() {
		saveTask?.cancel()
		saveTask = Task {
			try? await Task.sleep(for: .seconds(1))
			if Task.isCancelled { return }
			do { try context.save() } catch {}
			saveTask = nil
		}
	}

	public func updateAndSaveDebounce<Result: Sendable>(uid: String, _ updateFn: @escaping (inout T) -> Result) throws -> Result? {
		guard var data = try get(uid: uid) else { return nil }
		let result = updateFn(&data)
		saveDebounced()
		return result
	}

	public func fetch(_ descriptor: FetchDescriptor<T>) throws -> [T.SendableType] {
		try context.fetch(descriptor).map { $0.toSendable() }
	}
	public func delete(_ predicate: Predicate<T>) throws {
		try context.delete(model: T.self, where: predicate)
		try context.save()
	}
	public func fetch() throws -> [T.SendableType] {
		let descriptor = FetchDescriptor<T>()
		return try context.fetch(descriptor).map { $0.toSendable() }
	}

	private func get(id: PersistentIdentifier) -> T? {
		let data = self[id, as: T.self]
		fetchedLast = data
		return data
	}

	private func get(uid: String) throws -> T? {
		if fetchedLast?.uid == uid { return fetchedLast }
		let descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.uid == uid })
		let dataArr = try context.fetch(descriptor)
		fetchedLast = dataArr.first
		return fetchedLast
	}
}
