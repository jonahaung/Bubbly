//
//  ImageViewItem.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import UIKit
import XUI

public protocol ImageViewItem: Sendable, PhotoGalleryItem {
	var remoteURL: URL? { get }
	var imageID: String { get }
	var subFolders: [String] { get }
	var imageName: String? { get }
}

public extension ImageViewItem {
	func folder() -> Folder? {
		var document = Folder.documents

		do {
			try subFolders.forEach { each in
				document = try document?.createSubfolderIfNeeded(withName: each)
			}
		} catch {
			log(error)
			return nil
		}
		return document
	}

	func file() -> File? {
		do {
			return try folder()?.createFileIfNeeded(withName: fileName())
		} catch {
			log(error)
			return nil
		}
	}

	func thumbnailFile() -> File? {
		do {
			return try folder()?.createFileIfNeeded(withName: thumbnailFileName())
		} catch {
			log(error)
			return nil
		}
	}

	func fileName() -> String {
		imageID
	}

	func thumbnailFileName() -> String {
		"thumbnail_\(fileName())"
	}

	func fileExist() -> Bool {
		folder()?.containsFile(named: fileName()) == true
	}

	func thumbnailExist() -> Bool {
		folder()?.containsFile(named: thumbnailFileName()) == true
	}

	func data() -> Data? {
		do {
			return try file()?.read()
		} catch {
			log(error)
			return nil
		}
	}

	func thumbnailData() -> Data? {
		do {
			return try thumbnailFile()?.read()
		} catch {
			log(error)
			return nil
		}
	}

	func image() -> UIImage? {
		guard let data = data() else { return nil }
		return UIImage(data: data)
	}

	func thumbnailImage() -> UIImage? {
		guard let data = thumbnailData() else { return nil }
		return UIImage(data: data)
	}

	func localURL() -> URL? {
		file()?.url
	}
}

public extension ImageViewItem {
	var galleryURL: URL? {
		localURL() ?? remoteURL
	}
}
