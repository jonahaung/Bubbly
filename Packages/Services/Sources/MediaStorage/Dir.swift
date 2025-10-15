//
//  Dir.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation

// MARK: - FileSystemManager Protocol
protocol FileSystemManager: Sendable {
	func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
	func createDirectory(atPath path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws
}

extension FileManager: FileSystemManager {}

// MARK: - DirError Enum
enum DirError: Error {
	case directoryCreationFailed
	case directoryNotFound
	case invalidPath
}

// MARK: - Dir Class
final class Dir: Sendable {

	private let fileSystemManager: FileSystemManager

	init(fileSystemManager: FileSystemManager = FileManager.default) {
		self.fileSystemManager = fileSystemManager
	}

	// MARK: - Public Methods

	/// Returns the path to the Documents directory, optionally appending components.
	func document(_ components: String...) throws -> String {
		let documentsDirectory = try getDocumentsDirectory()
		return try createPath(in: documentsDirectory, components: components)
	}

	/// Returns the path to the Caches directory, optionally appending components.
	func cache(_ components: String...) throws -> String {
		let cachesDirectory = try getCachesDirectory()
		return try createPath(in: cachesDirectory, components: components)
	}

	/// Checks if a directory exists at the specified path.
	func directoryExists(atPath path: String) -> Bool {
		var isDirectory: ObjCBool = false
		return fileSystemManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
	}

	/// Creates intermediate directories for a given path if they don't already exist.
	func createIntermediateDirectories(for path: String) throws {
		let directory = (path as NSString).deletingLastPathComponent
		if !directoryExists(atPath: directory) {
			try fileSystemManager.createDirectory(
				atPath: directory,
				withIntermediateDirectories: true,
				attributes: nil
			)
		}
	}

	// MARK: - Private Methods

	/// Returns the path to the Documents directory.
	private func getDocumentsDirectory() throws -> String {
		guard let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
			throw DirError.directoryNotFound
		}
		return documentsDirectory
	}

	/// Returns the path to the Caches directory.
	private func getCachesDirectory() throws -> String {
		guard let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
			throw DirError.directoryNotFound
		}
		return cachesDirectory
	}

	/// Creates a path by appending components to a base directory.
	private func createPath(in directory: String, components: [String]) throws -> String {
		let path = components.reduce(directory) { ($0 as NSString).appendingPathComponent($1) }
		if directoryExists(atPath: path) {
			return path
		}
		try createIntermediateDirectories(for: path)
		return path
	}
}

extension Dir {
	class func application() -> String {
		return Bundle.main.resourcePath!
	}
	class func application(_ component: String) -> String {
		var path = application()
		path = (path as NSString).appendingPathComponent(component)
		return path
	}
	class func application(_ component1: String, and component2: String) -> String {
		var path = application()
		path = (path as NSString).appendingPathComponent(component1)
		path = (path as NSString).appendingPathComponent(component2)
		return path
	}
}
