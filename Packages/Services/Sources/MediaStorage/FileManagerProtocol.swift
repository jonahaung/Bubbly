//
//  FileManagerProtocol.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation

// MARK: - FileManagerProtocol
public protocol FileManagerProtocol: Sendable {
	func fileExists(atPath path: String) -> Bool
	func removeItem(atPath path: String) throws
	func createDirectory(atPath path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws
	func contentsOfDirectory(atPath path: String) throws -> [String]
	func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
	func copyItem(atPath srcPath: String, toPath dstPath: String) throws
}
extension FileManager: FileManagerProtocol, @unchecked @retroactive Sendable {}
