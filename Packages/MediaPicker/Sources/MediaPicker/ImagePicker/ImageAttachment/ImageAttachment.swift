//
//  ImageAttachment.swift
//  InlinePhotosPickerDemo
//
//  Created by Aung Ko Min on 25/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import PhotosUI

nonisolated
public final class ImageAttachment: @unchecked Sendable, Identifiable {
	public enum Status: Sendable {
        case loading
        case finished(UIImage)
        case failed(Error)
        var isFailed: Bool {
            return switch self {
            case .failed: true
            default: false
            }
        }
    }
    public var identifier: String {
        return pickerItem.identifier
    }
    enum LoadingError: Error {
        case contentTypeNotSupported
    }

	public let pickerItem: PhotosPickerItem

	public var imageStatus: Status?
	public var imageDescription: String = ""

    public let id: String

	public typealias ID = String

	public convenience init(itemIdentifier: ID) {
		self.init(PhotosPickerItem(itemIdentifier: itemIdentifier))
	}

	public init(_ item: PhotosPickerItem) {
		self.pickerItem = item
		if let id = item.itemIdentifier?.split(separator: "/").first {
			self.id = String(id)
		} else {
			self.id = UUID().uuidString
		}
	}

	public func loadTransferable<T: Transferable & Sendable>(type: T.Type) async throws -> sending T? {
		try await pickerItem.loadTransferable(type: T.self)
	}

    public func loadImage() async {
        guard imageStatus == nil || imageStatus?.isFailed == true else {
            return
        }
        imageStatus = .loading
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                imageStatus = .finished(uiImage)
            } else {
                throw LoadingError.contentTypeNotSupported
            }
        } catch {
            imageStatus = .failed(error)
        }
    }
    public func image() async -> UIImage? {
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                return uiImage
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
public extension PhotosPickerItem {
    var identifier: String {
        guard let identifier = itemIdentifier else {
            fatalError("The photos picker lacks a photo library.")
        }
        return identifier
    }
}
