//
//  FirestoreRepo.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

import Foundation
import Core
import XUI

public enum FirestoreRepo {

	nonisolated(unsafe) static let client = FirestoreRESTClient()

	public static func add<T: Codable & Sendable>(
		_ item: T,
		collectionPath: CollectionPath,
		documentID: String
	) async throws {
		try await client.createDocument(
			in: collectionPath.rawValue,
			documentID: documentID,
			data: item
		)
	}

	public static func update(
		value: sending [String: Any],
		collectionPath: CollectionPath,
		to documentID: String
	) async throws {
		try await client.update(value: value, collectionPath: collectionPath.rawValue, to: documentID)
	}

	public static func getModels<T: Codable & Sendable>(
		for uid: String,
		collection: CollectionPath,
		field: FieldPath
	) async throws -> [T] {
		let filter = FirestoreFilter(
			field: field.rawValue,
			operator: .arrayContains,
			value: .string(uid)
		)
		return try await client.query(collection: collection, filter: filter)
	}

	public static func getModel<T: Codable & Sendable>(
		for uid: String,
		collection: CollectionPath,
		field: FieldPath
	) async throws -> T? {
		let filter = FirestoreFilter(
			field: field.rawValue,
			operator: .equal,
			value: .string(uid)
		)
		let items: [T] = try await client.query(collection: collection, filter: filter)
		return items.first
	}
	
	public static func query<T: Codable & Sendable>(
		collection: CollectionPath,
		filters: sending [FirestoreFilter],
		orderBy: [String]? = nil,
		limit: Int? = nil
	) async throws -> [T] {
		try await client.query(
			collection: collection,
			filters: filters,
			orderBy: orderBy,
			limit: limit)
	}
}
