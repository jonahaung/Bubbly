//
//  DataCache.swift
//  XUI
//
//  Created by Aung Ko Min on 21/10/25.
//

import Foundation
import CryptoKit

public protocol DataCaching: Sendable {
	func cachedData(for key: String) -> Data?
	func containsData(for key: String) -> Bool
	func storeData(_ data: Data, for key: String)
	func removeData(for key: String)
	func removeAll()
}
public final class DataCache: DataCaching, @unchecked Sendable {
    public var sizeLimit: Int = 1024 * 1024 * 150
    var trimRatio = 0.7
    public let path: URL
    public var sweepInterval: TimeInterval = 3600

    private let lock = NSLock()
    private var staging = Staging()
    private var isFlushNeeded = false
    private var isFlushScheduled = false
    var flushInterval: DispatchTimeInterval = .seconds(1)

    private struct Metadata: Codable {
        var lastSweepDate: Date?
    }

    public let queue = DispatchQueue(label: "com.github.kean.Nuke.DataCache.WriteQueue", qos: .utility)

    public typealias FilenameGenerator = (_ key: String) -> String?

    private let filenameGenerator: FilenameGenerator

    public convenience init(name: String, filenameGenerator: @escaping (String) -> String? = DataCache.filename(for:)) throws {
        guard let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        try self.init(path: root.appendingPathComponent(name, isDirectory: true), filenameGenerator: filenameGenerator)
    }

    public init(path: URL, filenameGenerator: @escaping (String) -> String? = DataCache.filename(for:)) throws {
        self.path = path
        self.filenameGenerator = filenameGenerator
        try self.didInit()
    }

    public static func filename(for key: String) -> String? {
        key.isEmpty ? nil : key.sha1
    }

    private func didInit() throws {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        scheduleSweep()
    }

    private func scheduleSweep() {
        if let lastSweepDate = getMetadata().lastSweepDate,
           Date().timeIntervalSince(lastSweepDate) < sweepInterval {
            return
        }
        queue.asyncAfter(deadline: .now() + 5.0, qos: .background) { [weak self] in
            self?.performSweep()
            self?.updateMetadata { $0.lastSweepDate = Date() }
        }
    }

    public func cachedData(for key: String) -> Data? {
        if let change = change(for: key) {
            switch change {
            case let .add(data): return data
            case .remove: return nil
            }
        }
        guard let url = url(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    public func containsData(for key: String) -> Bool {
        if let change = change(for: key) {
            switch change {
            case .add: return true
            case .remove: return false
            }
        }
        guard let url = url(for: key) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    private func change(for key: String) -> Staging.ChangeType? {
        lock.lock()
        defer { lock.unlock() }
        return staging.change(for: key)
    }

    public func storeData(_ data: Data, for key: String) {
        stage { staging.add(data: data, for: key) }
    }

    public func removeData(for key: String) {
        stage { staging.removeData(for: key) }
    }

    public func removeAll() {
        stage { staging.removeAllStagedChanges() }
    }

    private func stage(_ change: () -> Void) {
        lock.lock()
        change()
        setNeedsFlushChanges()
        lock.unlock()
    }

    public subscript(key: String) -> Data? {
        get { cachedData(for: key) }
        set {
            if let data = newValue { storeData(data, for: key) }
            else { removeData(for: key) }
        }
    }

    public func filename(for key: String) -> String? {
        filenameGenerator(key)
    }

    public func url(for key: String) -> URL? {
        guard let filename = filename(for: key) else { return nil }
        return path.appendingPathComponent(filename, isDirectory: false)
    }

    private func setNeedsFlushChanges() {
        if isFlushNeeded { return }
        isFlushNeeded = true
        scheduleFlush()
    }

    private func scheduleFlush() {
        if isFlushScheduled { return }
        isFlushScheduled = true
        queue.asyncAfter(deadline: .now() + flushInterval) { [weak self] in
            self?.flush()
        }
    }

    private func flush() {
        lock.lock()
        let staged = staging
        staging = Staging()
        isFlushNeeded = false
        isFlushScheduled = false
        lock.unlock()

        for (key, change) in staged.changes {
            guard let url = url(for: key) else { continue }
            switch change {
            case let .add(data):
                try? data.write(to: url, options: .atomic)
            case .remove:
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func performSweep() {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else {
            return
        }

        var totalSize = 0
        var fileInfos: [(URL, Int, Date)] = []

        for url in urls {
            let resourceValues = try? url.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey])
            let fileSize = resourceValues?.fileSize ?? 0
            let accessDate = resourceValues?.contentAccessDate ?? Date()
            fileInfos.append((url, fileSize, accessDate))
            totalSize += fileSize
        }

        guard totalSize > sizeLimit else { return }

        let targetSize = Int(Double(sizeLimit) * trimRatio)
        let sorted = fileInfos.sorted { $0.2 < $1.2 }

        var size = totalSize
        for (url, fileSize, _) in sorted {
            try? FileManager.default.removeItem(at: url)
            size -= fileSize
            if size <= targetSize { break }
        }
    }

    private func getMetadata() -> Metadata {
        let url = path.appendingPathComponent("_metadata.json")
        guard let data = try? Data(contentsOf: url),
              let metadata = try? JSONDecoder().decode(Metadata.self, from: data) else {
            return Metadata()
        }
        return metadata
    }

    private func updateMetadata(_ update: (inout Metadata) -> Void) {
        var metadata = getMetadata()
        update(&metadata)
        let url = path.appendingPathComponent("_metadata.json")
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private struct Staging {
        enum ChangeType {
            case add(Data)
            case remove
        }
        var changes: [String: ChangeType] = [:]

        mutating func add(data: Data, for key: String) { changes[key] = .add(data) }
        mutating func removeData(for key: String) { changes[key] = .remove }
        mutating func removeAllStagedChanges() { changes.removeAll() }
        func change(for key: String) -> ChangeType? { changes[key] }
    }
}
extension String {
	/// Calculates SHA1 from the given string and returns its hex representation.
	///
	/// ```swift
	/// print("http://test.com".sha1)
	/// // prints "50334ee0b51600df6397ce93ceed4728c37fee4e"
	/// ```
	var sha1: String? {
		guard let input = self.data(using: .utf8) else {
			return nil // The conversion to .utf8 should never fail
		}
		let digest = Insecure.SHA1.hash(data: input)
		var output = ""
		for byte in digest {
			output.append(String(format: "%02x", byte))
		}
		return output
	}
}
