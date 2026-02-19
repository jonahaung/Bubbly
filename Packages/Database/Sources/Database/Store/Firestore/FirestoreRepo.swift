import Core

@NetworkActor
public enum FirestoreRepo {
	@NetworkActor private static let client = FirestoreRESTClient()

	public static func add(_ item: some Codable & Sendable,
	                       collectionPath: FirestoreCollectionPath,
	                       documentID: String) async throws
	{
		try await client.createDocument(
			in: collectionPath.rawValue,
			documentID: documentID,
			data: item
		)
	}

	public static func update(value: sending [String: Any],
	                          collectionPath: FirestoreCollectionPath,
	                          to documentID: String) async throws
	{
		try await client.update(
			value: value,
			collectionPath: collectionPath.rawValue,
			to: documentID
		)
	}

	public static func getModels<T: Codable & Sendable>(for uid: String,
	                                                    collection: FirestoreCollectionPath,
	                                                    field: FirestoreDocumentPath) async throws
		-> [
			T
		]
	{
		let filter = FirestoreFilter(
			field: field.rawValue,
			operator: .arrayContains,
			value: .string(uid)
		)
		return try await client.query(collection: collection, filter: filter)
	}

	public static func getModel<T: Codable & Sendable>(for uid: String,
	                                                   collection: FirestoreCollectionPath,
	                                                   field: FirestoreDocumentPath) async throws
		-> T?
	{
		let filter = FirestoreFilter(
			field: field.rawValue,
			operator: .equal,
			value: .string(uid)
		)
		let items: [T] = try await client.query(collection: collection, filter: filter)
		return items.first
	}

	public static func query<T: Codable & Sendable>(collection: FirestoreCollectionPath,
	                                                filters: sending [FirestoreFilter],
	                                                orderBy: [String]? = nil,
	                                                limit: Int? = nil) async throws -> [T]
	{
		try await client.query(
			collection: collection,
			filters: filters,
			orderBy: orderBy,
			limit: limit
		)
	}
}
