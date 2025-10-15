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

	public static func remove<T: Codable & Identifiable>(_ item: T, to ref: CollectionReference, completion: ((Error?) -> Void)? = nil) {
		guard let id = item.id as? String else {
			completion?(nil)
			return
		}
		ref.document(id).delete(completion: completion)
	}

	public static func fetchSingle<T: Codable>(query: Query) async throws -> T? {
		let items: [T] = try await fetch(query: query)
		return items.first
	}

	public static func fetch<T: Codable>(query: Query) async throws -> [T] {
		let snapshot = try await query.getDocuments()
		return snapshot.documents.compactMap { try? $0.data(as: T.self) }
	}

	public static func fetch<T: Codable>(query: Query, completion: @escaping (Result<[T], Error>) -> Void) {
		query.getDocuments { snapshot, error in
			if let error {
				completion(.failure(error))
			} else if let snapshot {
				let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
				completion(.success(items))
			}
		}
	}

	public static func fetch<T: Codable>(query: Query, completion: @escaping (Result<T?, Error>) -> Void) {
		query.getDocuments { snapshot, error in
			if let error {
				completion(.failure(error))
			} else if let snapshot {
				let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
				completion(.success(items.first))
			}
		}
	}
}
