//
//  Storage.swift
//  XUI
//
//  Created by Aung Ko Min on 21/10/25.
//

import Foundation

public final class Storage<LocationType: Location> {
    private(set) var path: String
    private let fileManager: FileManager

    init(path: String, fileManager: FileManager) throws {
        self.path = path
        self.fileManager = fileManager
        try validatePath()
    }

    private func validatePath() throws {
        switch LocationType.kind {
        case .file:
            guard !path.isEmpty else {
                throw LocationError(path: path, reason: .emptyFilePath)
            }
        case .folder:
            if path.isEmpty { path = fileManager.currentDirectoryPath }
            if !path.hasSuffix("/") { path += "/" }
        }

        if path.hasPrefix("~") {
            let homePath = ProcessInfo.processInfo.environment["HOME"]!
            path = homePath + path.dropFirst()
        }

        while let parentReferenceRange = path.range(of: "../") {
            let folderPath = String(path[..<parentReferenceRange.lowerBound])
            let parentPath = makeParentPath(for: folderPath) ?? "/"

            guard fileManager.locationExists(at: parentPath, kind: .folder) else {
                throw LocationError(path: parentPath, reason: .missing)
            }

            path.replaceSubrange(..<parentReferenceRange.upperBound, with: parentPath)
        }

        guard fileManager.locationExists(at: path, kind: LocationType.kind) else {
            throw LocationError(path: path, reason: .missing)
        }
    }
}

extension Storage {
    var attributes: [FileAttributeKey: Any] {
        (try? fileManager.attributesOfItem(atPath: path)) ?? [:]
    }

    func makeParentPath(for path: String) -> String? {
        guard path != "/" else { return nil }
        let url = URL(fileURLWithPath: path)
        let components = url.pathComponents.dropFirst().dropLast()
        guard !components.isEmpty else { return "/" }
        return "/" + components.joined(separator: "/") + "/"
    }

    func move(to newPath: String,
              errorReasonProvider: (Error) -> LocationErrorReason) throws {
        do {
            try fileManager.moveItem(atPath: path, toPath: newPath)

            switch LocationType.kind {
            case .file:
                path = newPath
            case .folder:
                path = newPath.appendingSuffixIfNeeded("/")
            }
        } catch {
            throw LocationError(path: path, reason: errorReasonProvider(error))
        }
    }

    func copy(to newPath: String) throws {
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: path),
                                     to: URL(fileURLWithPath: newPath))

        } catch {
            throw LocationError(path: path, reason: .copyFailed(error))
        }
    }

    func delete() throws {
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            throw LocationError(path: path, reason: .deleteFailed(error))
        }
    }
}

extension Storage where LocationType == Folder {
    func makeChildSequence<T: Location>() -> Folder.ChildSequence<T> {
        Folder.ChildSequence(
            folder: Folder(storage: self),
            fileManager: fileManager,
            isRecursive: false,
            includeHidden: false
        )
    }

    func subfolder(at folderPath: String) throws -> Folder {
        let folderPath = path + folderPath.removingPrefix("/")
        let storage = try Storage(path: folderPath, fileManager: fileManager)
        return Folder(storage: storage)
    }

    func file(at filePath: String) throws -> File {
        let filePath = path + filePath.removingPrefix("/")
        let storage = try Storage<File>(path: filePath, fileManager: fileManager)
        return File(storage: storage)
    }

    func createSubfolder(at folderPath: String) throws -> Folder {
        let folderPath = path + folderPath.removingPrefix("/")

        guard folderPath != path else {
            throw WriteError(path: folderPath, reason: .emptyPath)
        }

        do {
            try fileManager.createDirectory(
                atPath: folderPath,
                withIntermediateDirectories: true
            )

            let storage = try Storage(path: folderPath, fileManager: fileManager)
            return Folder(storage: storage)
        } catch {
            throw WriteError(path: folderPath, reason: .folderCreationFailed(error))
        }
    }

    func createFile(at filePath: String, contents: Data?) throws -> File {
        let filePath = path + filePath.removingPrefix("/")

        guard let parentPath = makeParentPath(for: filePath) else {
            throw WriteError(path: filePath, reason: .emptyPath)
        }

        if parentPath != path {
            do {
                try fileManager.createDirectory(
                    atPath: parentPath,
                    withIntermediateDirectories: true
                )
            } catch {
                throw WriteError(path: parentPath, reason: .folderCreationFailed(error))
            }
        }

        guard fileManager.createFile(atPath: filePath, contents: contents),
              let storage = try? Storage<File>(path: filePath, fileManager: fileManager)
        else {
            throw WriteError(path: filePath, reason: .fileCreationFailed)
        }

        return File(storage: storage)
    }
}
