//
//  DbQuery.swift
//  Database
//
//  Created by Aung Ko Min on 13/7/25.
//

import SwiftData
import SwiftUI

public struct DbQuery<T>: View where T: PersistentModel & CollectionDocument & SendableDocument {
	@Query private var items: [T]
	private let content: (_ items: [T]) -> AnyView

	public init(
		predicate: Predicate<T>? = nil,
		sortBy: [SortDescriptor<T>] = [],
		fetchLimit: Int? = nil,
		@ViewBuilder content: @escaping (_ items: [T]) -> some View
	) {
		var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
		if let fetchLimit {
			descriptor.fetchLimit = fetchLimit
		}

		_items = Query(descriptor)
		self.content = { items in AnyView(content(items)) }
	}

	// Convenience: build a row per item; we wrap it in a ForEach.
	public init(
		predicate: Predicate<T>? = nil,
		sortBy: [SortDescriptor<T>] = [],
		fetchLimit: Int? = nil,
		@ViewBuilder row: @escaping (_ item: T) -> some View
	) where T: Identifiable {
		var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
		if let fetchLimit {
			descriptor.fetchLimit = fetchLimit
		}

		_items = Query(descriptor)
		content = { items in
			AnyView(
				ForEach(items) { item in
					row(item)
				}
			)
		}
	}

	public var body: some View {
		content(items)
	}
}
