//
//  ImageViewItem.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import UIKit
import XUI

public protocol ImageViewItem: Sendable {
	var remoteURL: URL? { get }
	var imageID: String? { get }
	var subFolderName: String? { get }
	var folderName: String? { get }
	var mediaType: MediaType? { get }
}

public extension ImageViewItem {
	var folderName: String? {
		mediaType?.directory
	}
	func folder() -> Folder? {
		guard let folderName,
			  let subFolderName else { return nil }
		do {
			return try Folder.documents?
				.createSubfolderIfNeeded(withName: folderName)
				.createSubfolderIfNeeded(withName: subFolderName)
		} catch {
			Log(error)
			return nil
		}
	}

	func file() -> File? {
		guard let fileName = fileName() else { return nil }
		do {
			return try folder()?.createFileIfNeeded(withName: fileName)
		} catch {
			Log(error)
			return nil
		}
	}

	func thumbnailFile() -> File? {
		guard let thumbnailFileName = thumbnailFileName() else { return nil }
		do {
			return try folder()?.createFileIfNeeded(withName: thumbnailFileName)
		} catch {
			Log(error)
			return nil
		}
	}

	// MARK: - File Name

	func fileName() -> String? {
		guard let imageID, let mediaType else { return nil }
		return imageID + mediaType.fileExtension
	}

	func thumbnailFileName() -> String? {
		guard let name = fileName() else { return nil }
		return "thumbnail_\(name)"
	}

	// MARK: - File Checks

	func fileExist() -> Bool {
		guard let fileName = fileName() else { return false }
		return folder()?.containsFile(named: fileName) == true
	}

	// MARK: - Data

	func data() -> Data? {
		do {
			return try file()?.read()
		} catch {
			Log(error)
			return nil
		}
	}

	func thumbnailData() -> Data? {
		do {
			return try thumbnailFile()?.read()
		} catch {
			Log(error)
			return nil
		}
	}

	// MARK: - Images

	func image() -> UIImage? {
		guard let data = data() else { return nil }
		return UIImage(data: data)
	}

	func thumbnailImage() -> UIImage? {
		guard let data = thumbnailData() else { return nil }
		return UIImage(data: data)
	}

	// MARK: - URL

	func localURL() -> URL? {
		file()?.url
	}
}
