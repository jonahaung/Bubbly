//
//  File.swift
//  XUI
//
//  Created by Aung Ko Min on 20/10/25.
//

import Foundation

public struct File: Location, Identifiable {
    public var id: String { path }

    public let storage: Storage<File>

    public init(storage: Storage<File>) {
        self.storage = storage
    }
}

public extension File {
    static var kind: LocationKind {
        .file
    }

    func write(_ data: Data) throws {
        do {
            try data.write(to: url)
        } catch {
            throw WriteError(path: path, reason: .writeFailed(error))
        }
    }

    func write(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw WriteError(path: path, reason: .stringEncodingFailed(string))
        }

        return try write(data)
    }

    func append(_ data: Data) throws {
        do {
            let handle = try FileHandle(forWritingTo: url)
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } catch {
            throw WriteError(path: path, reason: .writeFailed(error))
        }
    }

    func append(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw WriteError(path: path, reason: .stringEncodingFailed(string))
        }

        return try append(data)
    }

    func read() throws -> Data {
        do { return try Data(contentsOf: url) } catch { throw ReadError(path: path, reason: .readFailed(error)) }
    }

    func readAsString(encodedAs encoding: String.Encoding = .utf8) throws -> String {
        guard let string = try String(data: read(), encoding: encoding) else {
            throw ReadError(path: path, reason: .stringDecodingFailed)
        }

        return string
    }

    func readAsInt() throws -> Int {
        let string = try readAsString()

        guard let int = Int(string) else {
            throw ReadError(path: path, reason: .notAnInt(string))
        }

        return int
    }
}

extension FileManager {
    func locationExists(at path: String, kind: LocationKind) -> Bool {
        var isFolder: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &isFolder) else {
            return false
        }

        switch kind {
        case .file: return !isFolder.boolValue
        case .folder: return isFolder.boolValue
        }
    }
}
