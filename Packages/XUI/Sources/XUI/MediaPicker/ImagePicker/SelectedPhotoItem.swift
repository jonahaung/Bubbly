//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import PhotosUI
import SwiftUI

public struct SelectedPhotoItem: Sendable, Equatable, Identifiable {
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
            id = UUID().uuidString
        }
    }

    public func loadTransferable<T: Transferable & Sendable>(type _: T
        .Type) async throws -> sending T? {
        try await item.loadTransferable(type: T.self)
    }
}

public struct SelectedImage: Sendable, Equatable, Identifiable {
    public let id: String
    public let image: UIImage

    public init(id: String, image: UIImage) {
        self.id = id
        self.image = image
    }
}
