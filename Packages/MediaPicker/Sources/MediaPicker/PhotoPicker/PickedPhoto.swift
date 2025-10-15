//
//  PickedPhoto.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 26/8/25.
//

import SwiftUI

public struct PickedPhoto: Transferable, Sendable, Hashable {
	public let uiImage: UIImage
	public static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(importedContentType: .image) { data in
			guard let uiImage = UIImage(data: data) else {
				throw PhotoPickerError.importFailed
			}
			return PickedPhoto(uiImage: uiImage)
		}
	}
}
