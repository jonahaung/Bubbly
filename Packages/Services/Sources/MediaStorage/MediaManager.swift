//
//  MediaManager.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation
import UIKit
// MARK: - MediaManager Class
public final class MediaManager: Sendable {

	private let fileManager = FileManager.default
	private let dir = Dir()

	public static let shared = MediaManager()

	private init() {}

	// MARK: - Path Management
	public func path(for id: String, _ type: MediaType) -> String {
		let filePath = try! dir.document(
			type.directory,
			"\(id).\(type.fileExtension)"
		)
		return filePath
	}
	public func thumbnilPath(for id: String, _ type: MediaType) -> String {
		let filePath = try! dir.document(
			type.directory,
			"\(id)_thumbnil.\(type.fileExtension)"
		)
		return filePath
	}
	public func url(for id: String, _ type: MediaType) -> URL {
		.init(filePath: path(for: id, type))
	}
	public func thumbnilUrl(for id: String, _ type: MediaType) -> URL {
		.init(filePath: thumbnilPath(for: id, type))
	}

	// MARK: - Save Media
	public func save(_ id: String, data: Data, _ type: MediaType) throws {
		let filePath = path(for: id, type)
		try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
	}

	public func saveThumbnil(_ id: String, data: Data, _ type: MediaType) throws {
		let filePath = thumbnilPath(for: id, type)
		try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
	}

	public func fileExist(for id: String, _ type: MediaType) -> Bool {
		fileManager.fileExists(atPath: path(for: id, type))
	}
	public func thumbnilExist(for id: String, _ type: MediaType) -> Bool {
		fileManager.fileExists(atPath: thumbnilPath(for: id, type))
	}

	public func createThumbnil(from uiImage: UIImage) async throws -> Data {
		guard let data = uiImage.resized(toWidth: 220)?.pngData() else {
			throw NSError(domain: "Falied to create thumbnil", code: 0)
		}
		return data
//		let sticker = try await StickerProcessor().process(data: data)
//		return sticker.sticker.pngData() ?? data
	}
	public func createData(from uiImage: UIImage) throws -> Data {
		guard let data = uiImage.pngData() else {
			throw NSError(domain: "Falied to create data", code: 0)
		}
		return data
	}

	public func remove(for id: String, _ type: MediaType) throws {
		try fileManager.removeItem(atPath: path(for: id, type))
		try fileManager.removeItem(atPath: thumbnilPath(for: id, type))
	}
	public func removeThumbnil(for id: String, _ type: MediaType) throws {
		try fileManager.removeItem(atPath: thumbnilPath(for: id, type))
	}
	public func cleanupExpired(using policy: MediaRetentionPolicy) throws {
		switch policy {
		case .month:
			try cleanupExpired(days: 30)
		case .week:
			try cleanupExpired(days: 7)
		case .unknown:
			break
		}
	}

	private func cleanupExpired(days: Int) throws {
		let pastDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
		try cleanupFiles(
			in: dir.document(.empty),
			extensions: MediaType.allCases.map{ $0.fileExtension },
			olderThan: pastDate
		)
		try cleanupFiles(
			in: dir.cache(.empty),
			extensions: ["mp4"],
			olderThan: pastDate
		)
	}

	private func cleanupFiles(in directory: String, extensions: [String], olderThan date: Date) throws {
		let files = try fileManager.contentsOfDirectory(atPath: directory)
		for file in files {
			let filePath = (directory as NSString).appendingPathComponent(file)
			let attributes = try fileManager.attributesOfItem(atPath: filePath)
			if let creationDate = attributes[.creationDate] as? Date, creationDate < date {
				try fileManager.removeItem(atPath: filePath)
			}
		}
	}

	// MARK: - Total Size Calculation
	public func totalSize() throws -> Int64 {
		let documentSize = try totalSize(
			in: dir.document(.empty),
			extensions: ["jpg", "mp4", "m4a"]
		)
		let cacheSize = try totalSize(
			in: dir.cache(.empty),
			extensions: ["mp4"]
		)
		return documentSize + cacheSize
	}

	private func totalSize(in directory: String, extensions: [String]) throws -> Int64 {
		let files = try fileManager.contentsOfDirectory(atPath: directory)
		var total: Int64 = 0
		for file in files {
			let filePath = (directory as NSString).appendingPathComponent(file)
			let attributes = try fileManager.attributesOfItem(atPath: filePath)
			if let fileSize = attributes[.size] as? Int64 {
				total += fileSize
			}
		}
		return total
	}
}
