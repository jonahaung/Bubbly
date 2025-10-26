//
//  FirestoreRepo.swift
//  Msgr
//
//  Created by Aung Ko Min on 4/11/22.
//

import Foundation
import FirebaseFirestore
import Database

public struct FirestoreRepo {

	public static func add<T: Codable & UIdentifiable>(_ item: T, to ref: DocumentReference) async throws where T.UID == String {
		try await ref.setData(item.dictionary)
	}

	public static func update<T: Codable & UIdentifiable>(_ item: T, to ref: DocumentReference) async throws {
		try await ref.setData(item.dictionary)
	}
	
	public static func fetchSingle<T>(query: Query) async throws -> T? where T: Codable & Sendable & SendableMetatype {
		let items: [T] = try await fetch(query: query)
		return items.first
	}

	public static func fetch<T>(query: Query) async throws -> [T]
	where T: Codable & Sendable & SendableMetatype {
		let snapshot = try await query.getDocuments()
		return snapshot.documents.compactMap { try? $0.data(as: T.self) }
	}
}
