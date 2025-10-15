//
//  SelectedPhoto.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 1/10/25.
//

import SwiftUI
import PhotosUI

public struct SelectedPhoto: Sendable, Equatable, Identifiable {
	public typealias ID = String

	public let id: ID
	public let item: PhotosPickerItem

	public init(itemIdentifier: ID) {
		self.init(PhotosPickerItem(itemIdentifier: itemIdentifier))
	}

	public init(_ item: PhotosPickerItem) {
		self.item = item
		if let id = item.itemIdentifier?.split(separator: "/").first {
			self.id = String(id)
		} else {
			self.id = UUID().uuidString
		}
	}

	public func loadTransferable<T: Transferable & Sendable>(type: T.Type) async throws -> sending T? {
		try await item.loadTransferable(type: T.self)
	}
}
public struct StickerResult: Sendable, Identifiable {
	public let id: SelectedPhoto.ID
	public let uiImage: UIImage

	public init(id: SelectedPhoto.ID, uiImage: UIImage) {
		self.id = id
		self.uiImage = uiImage
	}
}
