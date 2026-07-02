//  FilesError.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public struct FilesError<Reason: Sendable>: Error {
    public var path: String
    public var reason: Reason

    public init(path: String, reason: Reason) {
        self.path = path
        self.reason = reason
    }
}

extension FilesError: CustomStringConvertible {
    public var description: String {
        """
        Files encountered an error at '\(path)'.
        Reason: \(reason)
        """
    }
}

public enum LocationErrorReason: Sendable {
    case missing
    case emptyFilePath
    case cannotRenameRoot
    case renameFailed(Error)
    case moveFailed(Error)
    case copyFailed(Error)
    case deleteFailed(Error)
    case unresolvedSearchPath(
        FileManager.SearchPathDirectory,
        domain: FileManager.SearchPathDomainMask
    )
}

public enum WriteErrorReason: Sendable {
    case emptyPath
    case folderCreationFailed(Error)
    case fileCreationFailed
    case writeFailed(Error)
    case stringEncodingFailed(String)
}

public enum ReadErrorReason: Sendable {
    case readFailed(Error)
    case stringDecodingFailed
    case notAnInt(String)
}

public typealias LocationError = FilesError<LocationErrorReason>
public typealias WriteError = FilesError<WriteErrorReason>
public typealias ReadError = FilesError<ReadErrorReason>
