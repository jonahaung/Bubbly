//
//  Folder.swift
//  XUI
//
//  Created by Aung Ko Min on 21/10/25.
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    public extension File {
        func open() {
            NSWorkspace.shared.openFile(path)
        }
    }
#endif

public struct Folder: Location {
    public var id: String { path }

    public let storage: Storage<Folder>

    public init(storage: Storage<Folder>) {
        self.storage = storage
    }
}

public extension Folder {
    struct ChildSequence<Child: Location>: Sequence, Identifiable {
        public var id: String { folder.path }
        fileprivate let folder: Folder
        fileprivate let fileManager: FileManager
        fileprivate var isRecursive: Bool
        fileprivate var includeHidden: Bool

        init(folder: Folder, fileManager: FileManager, isRecursive: Bool, includeHidden: Bool) {
            self.folder = folder
            self.fileManager = fileManager
            self.isRecursive = isRecursive
            self.includeHidden = includeHidden
        }

        public func makeIterator() -> ChildIterator<Child> {
            ChildIterator(
                folder: folder,
                fileManager: fileManager,
                isRecursive: isRecursive,
                includeHidden: includeHidden,
                reverseTopLevelTraversal: false
            )
        }
    }

    struct ChildIterator<Child: Location>: IteratorProtocol {
        private let folder: Folder
        private let fileManager: FileManager
        private let isRecursive: Bool
        private let includeHidden: Bool
        private let reverseTopLevelTraversal: Bool
        private lazy var itemNames = loadItemNames()
        private var index = 0
        private var nestedIterators = [ChildIterator<Child>]()

        init(folder: Folder,
             fileManager: FileManager,
             isRecursive: Bool,
             includeHidden: Bool,
             reverseTopLevelTraversal: Bool) {
            self.folder = folder
            self.fileManager = fileManager
            self.isRecursive = isRecursive
            self.includeHidden = includeHidden
            self.reverseTopLevelTraversal = reverseTopLevelTraversal
        }

        public mutating func next() -> Child? {
            guard index < itemNames.count else {
                guard var nested = nestedIterators.first else {
                    return nil
                }

                guard let child = nested.next() else {
                    nestedIterators.removeFirst()
                    return next()
                }

                nestedIterators[0] = nested
                return child
            }

            let name = itemNames[index]
            index += 1

            if !includeHidden {
                guard !name.hasPrefix(".") else { return next() }
            }

            let childPath = folder.path + name.removingPrefix("/")
            let childStorage = try? Storage<Child>(path: childPath, fileManager: fileManager)
            let child = childStorage.map(Child.init)

            if isRecursive {
                let childFolder = (child as? Folder) ?? (try? Folder(
                    storage: Storage(path: childPath, fileManager: fileManager)
                ))

                if let childFolder {
                    let nested = ChildIterator(
                        folder: childFolder,
                        fileManager: fileManager,
                        isRecursive: true,
                        includeHidden: includeHidden,
                        reverseTopLevelTraversal: false
                    )

                    nestedIterators.append(nested)
                }
            }

            return child ?? next()
        }

        private mutating func loadItemNames() -> [String] {
            let contents = try? fileManager.contentsOfDirectory(atPath: folder.path)
            let names = contents?.sorted() ?? []
            return reverseTopLevelTraversal ? names.reversed() : names
        }
    }
}

extension Folder.ChildSequence: CustomStringConvertible {
    public var description: String {
        lazy.map(\.description).joined(separator: "\n")
    }
}

public extension Folder.ChildSequence {
    var recursive: Folder.ChildSequence<Child> {
        var sequence = self
        sequence.isRecursive = true
        return sequence
    }

    var includingHidden: Folder.ChildSequence<Child> {
        var sequence = self
        sequence.includeHidden = true
        return sequence
    }

    func count() -> Int {
        reduce(0) { count, _ in count + 1 }
    }

    func names() -> [String] {
        map(\.name)
    }

    func last() -> Child? {
        var iterator = Iterator(
            folder: folder,
            fileManager: fileManager,
            isRecursive: isRecursive,
            includeHidden: includeHidden,
            reverseTopLevelTraversal: !isRecursive
        )

        guard isRecursive else { return iterator.next() }

        var child: Child?

        while let nextChild = iterator.next() {
            child = nextChild
        }

        return child
    }

    var first: Child? {
        var iterator = makeIterator()
        return iterator.next()
    }

    func move(to folder: Folder) throws {
        try forEach { try $0.move(to: folder) }
    }

    func delete() throws {
        try forEach { try $0.delete() }
    }
}

public extension Folder {
    static var kind: LocationKind {
        .folder
    }
    static var current: Folder {
        try! Folder(path: "")
    }

    static var root: Folder {
        try! Folder(path: "/")
    }

    static var home: Folder {
        try! Folder(path: "~")
    }

    static var temporary: Folder {
        try! Folder(path: NSTemporaryDirectory())
    }

    var subfolders: ChildSequence<Folder> {
        storage.makeChildSequence()
    }

    var files: ChildSequence<File> {
        storage.makeChildSequence()
    }

    func subfolder(at path: String) throws -> Folder {
        try storage.subfolder(at: path)
    }

    func subfolder(named name: String) throws -> Folder {
        try storage.subfolder(at: name)
    }

    func containsSubfolder(at path: String) -> Bool {
        (try? subfolder(at: path)) != nil
    }

    func containsSubfolder(named name: String) -> Bool {
        (try? subfolder(named: name)) != nil
    }

    @discardableResult
    func createSubfolder(at path: String) throws -> Folder {
        try storage.createSubfolder(at: path)
    }

    @discardableResult
    func createSubfolder(named name: String) throws -> Folder {
        try storage.createSubfolder(at: name)
    }

    @discardableResult
    func createSubfolderIfNeeded(at path: String) throws -> Folder {
        try (try? subfolder(at: path)) ?? createSubfolder(at: path)
    }

    @discardableResult
    func createSubfolderIfNeeded(withName name: String) throws -> Folder {
        try (try? subfolder(named: name)) ?? createSubfolder(named: name)
    }

    func file(at path: String) throws -> File {
        try storage.file(at: path)
    }

    func file(named name: String) throws -> File {
        try storage.file(at: name)
    }

    func containsFile(at path: String) -> Bool {
        (try? file(at: path)) != nil
    }

    func containsFile(named name: String) -> Bool {
        (try? file(named: name)) != nil
    }

    @discardableResult
    func createFile(at path: String, contents: Data? = nil) throws -> File {
        try storage.createFile(at: path, contents: contents)
    }

    @discardableResult
    func createFile(named fileName: String, contents: Data? = nil) throws -> File {
        try storage.createFile(at: fileName, contents: contents)
    }

    @discardableResult
    func createFileIfNeeded(at path: String,
                            contents: @autoclosure () -> Data? = nil) throws -> File {
        try (try? file(at: path)) ?? createFile(at: path, contents: contents())
    }

    @discardableResult
    func createFileIfNeeded(withName name: String,
                            contents: @autoclosure () -> Data? = nil) throws -> File {
        try (try? file(named: name)) ?? createFile(named: name, contents: contents())
    }

    func contains<T: Location>(_ location: T) -> Bool {
        switch T.kind {
        case .file: containsFile(named: location.name)
        case .folder: containsSubfolder(named: location.name)
        }
    }

    func moveContents(to folder: Folder, includeHidden: Bool = false) throws {
        var files = files
        files.includeHidden = includeHidden
        try files.move(to: folder)

        var folders = subfolders
        folders.includeHidden = includeHidden
        try folders.move(to: folder)
    }

    func empty(includingHidden includeHidden: Bool = false) throws {
        var files = files
        files.includeHidden = includeHidden
        try files.delete()

        var folders = subfolders
        folders.includeHidden = includeHidden
        try folders.delete()
    }

    func isEmpty(includingHidden includeHidden: Bool = false) -> Bool {
        var files = files
        files.includeHidden = includeHidden

        if files.first != nil {
            return false
        }

        var folders = subfolders
        folders.includeHidden = includeHidden
        return folders.first == nil
    }
}

public extension Folder {
	static func matching(
		_ searchPath: FileManager.SearchPathDirectory,
		in domain: FileManager.SearchPathDomainMask = .userDomainMask,
		resolvedBy fileManager: FileManager = .default
	) throws -> Folder {
		let urls = fileManager.urls(for: searchPath, in: domain)

		guard let match = urls.first else {
			throw LocationError(
				path: "",
				reason: .unresolvedSearchPath(searchPath, domain: domain)
			)
		}

		return try Folder(storage: Storage(
			path: match.relativePath,
			fileManager: fileManager
		))
	}

	static var documents: Folder? {
		return try? .matching(.documentDirectory)
	}

	static var library: Folder? {
		return try? .matching(.libraryDirectory)
	}
}
extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    func appendingSuffixIfNeeded(_ suffix: String) -> String {
        guard !hasSuffix(suffix) else { return self }
        return appending(suffix)
    }
}
