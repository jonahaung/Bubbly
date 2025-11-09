//
//  Location.swift
//  XUI
//
//  Created by Aung Ko Min on 21/10/25.
//
import Foundation

public enum LocationKind {
    case file
    case folder
}

public protocol Location: Equatable, CustomStringConvertible, Identifiable {
    static var kind: LocationKind { get }
    var storage: Storage<Self> { get }
    init(storage: Storage<Self>)
}

public extension Location {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage.path == rhs.storage.path
    }

    var description: String {
        let typeName = String(describing: type(of: self))
        return "\(typeName)(name: \(name), path: \(path))"
    }

    var path: String {
        storage.path
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    var name: String {
        url.pathComponents.last!
    }

    var nameExcludingExtension: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return name }
        return components.dropLast().joined()
    }

    var `extension`: String? {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return nil }
        return String(components.last!)
    }

    var parent: Folder? {
        storage.makeParentPath(for: path).flatMap {
            try? Folder(path: $0)
        }
    }

    var creationDate: Date? {
        storage.attributes[.creationDate] as? Date
    }

    var modificationDate: Date? {
        storage.attributes[.modificationDate] as? Date
    }

    init(path: String) throws {
        try self.init(storage: Storage(
            path: path,
            fileManager: .default
        ))
    }

    func path(relativeTo folder: Folder) -> String {
        guard path.hasPrefix(folder.path) else {
            return path
        }

        let index = path.index(path.startIndex, offsetBy: folder.path.count)
        return String(path[index...]).removingSuffix("/")
    }

    func rename(to newName: String, keepExtension: Bool = true) throws {
        guard let parent else {
            throw LocationError(path: path, reason: .cannotRenameRoot)
        }

        var newName = newName

        if keepExtension {
            `extension`.map {
                newName = newName.appendingSuffixIfNeeded(".\($0)")
            }
        }

        try storage.move(
            to: parent.path + newName,
            errorReasonProvider: LocationErrorReason.renameFailed
        )
    }

    func move(to newParent: Folder) throws {
        try storage.move(
            to: newParent.path + name,
            errorReasonProvider: LocationErrorReason.moveFailed
        )
    }

    @discardableResult
    func copy(to folder: Folder) throws -> Self {
        let path = folder.path + name
        try storage.copy(to: path)
        return try Self(path: path)
    }

    func delete() throws {
        try storage.delete()
    }

    func managedBy(_ manager: FileManager) throws -> Self {
        try Self(storage: Storage(
            path: path,
            fileManager: manager
        ))
    }
}
