//
//  DbQuery.swift
//  Database
//
//  Created by Aung Ko Min on 13/7/25.
//

import SwiftData
import SwiftUI

public struct DbQuery<T, Content: View>: View where T: PersistentModel & CollectionDocument & SendableDocument {

	@Query private var items: [T]
	private let content: (_ items: [T]) -> Content

	public init(
		predicate: Predicate<T>? = nil,
		sortBy: [SortDescriptor<T>] = [],
		fetchLimit: Int? = nil,
		@ViewBuilder content: @escaping (_ items: [T]) -> Content
	) {
		var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
		if let fetchLimit = fetchLimit {
			descriptor.fetchLimit = fetchLimit
		}

		_items = Query(descriptor)
		self.content = content
	}

	public var body: some View { content(items) }
}
