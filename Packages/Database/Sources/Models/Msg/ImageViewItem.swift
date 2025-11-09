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

extension ImageViewItem {
	public var folderName: String? {
		mediaType?.directory
	}

	public func folder() -> Folder? {
		guard let folderName,
			let subFolderName
		else { return nil }
		do {
			return try Folder.documents?
				.createSubfolderIfNeeded(withName: folderName)
				.createSubfolderIfNeeded(withName: subFolderName)
		} catch {
			Log(error)
			return nil
		}
	}

	public func file() -> File? {
		guard let fileName = fileName() else { return nil }
		do {
			return try folder()?.createFileIfNeeded(withName: fileName)
		} catch {
			Log(error)
			return nil
		}
	}

	public func thumbnailFile() -> File? {
		guard let thumbnailFileName = thumbnailFileName() else { return nil }
		do {
			return try folder()?.createFileIfNeeded(withName: thumbnailFileName)
		} catch {
			Log(error)
			return nil
		}
	}

	public func fileName() -> String? {
		guard let imageID, let mediaType else { return nil }
		return imageID + mediaType.fileExtension
	}

	public func thumbnailFileName() -> String? {
		guard let name = fileName() else { return nil }
		return "thumbnail_\(name)"
	}

	public func fileExist() -> Bool {
		guard let fileName = fileName() else { return false }
		return folder()?.containsFile(named: fileName) == true
	}

	public func data() -> Data? {
		do {
			return try file()?.read()
		} catch {
			Log(error)
			return nil
		}
	}

	public func thumbnailData() -> Data? {
		do {
			return try thumbnailFile()?.read()
		} catch {
			Log(error)
			return nil
		}
	}

	public func image() -> UIImage? {
		guard let data = data() else { return nil }
		return UIImage(data: data)
	}

	public func thumbnailImage() -> UIImage? {
		guard let data = thumbnailData() else { return nil }
		return UIImage(data: data)
	}

	public func localURL() -> URL? {
		file()?.url
	}
}
