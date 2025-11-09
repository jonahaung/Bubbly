//
//  ImagePickerSingle.swift
//
//
//  Created by Aung Ko Min on 18/7/23.
//

import SwiftUI

public class DirUtil: NSObject {
    class func application() -> String? {
        Bundle.main.resourcePath
    }

    class func application(_ component: String) -> String? {
        guard let basePath = application() else { return nil }
        return (basePath as NSString).appendingPathComponent(component)
    }

    // -------------------------------------------------------------------------------------------------------------------------------------------
    class func application(_ component1: String, and component2: String) -> String? {
        guard let basePath = application() else { return nil }
        let pathWithComponent1 = (basePath as NSString).appendingPathComponent(component1)
        return (pathWithComponent1 as NSString).appendingPathComponent(component2)
    }
}

public extension DirUtil {
    class func document() -> String? {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }

    class func document(_ components: [String]) -> String? {
        guard var path = document() else { return nil }
        for component in components {
            path = (path as NSString).appendingPathComponent(component)
        }
        createIntermediate(path)
        return path
    }
}

public extension DirUtil {
    class func cache() -> String? {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
    }

    class func cache(_ component: String) -> String? {
        guard var path = cache() else { return nil }
        path = (path as NSString).appendingPathComponent(component)
        createIntermediate(path)
        return path
    }
}

public extension DirUtil {
    private class func createIntermediate(_ path: String) {
        let directory = (path as NSString).deletingLastPathComponent
        if !exist(directory) {
            create(directory)
        }
    }

    private class func create(_ directory: String) {
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint("Failed to create directory at \(directory): \(error.localizedDescription)")
        }
    }

    private class func exist(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

public enum FileUtil {
    public static var documentDirectory: URL? {
        url(for: .documentDirectory)
    }

    public static var cachesDirectory: URL? {
        url(for: .cachesDirectory)
    }

    public static var temporaryDirectory: URL {
        .init(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    public static func url(for searchPathDirectory: FileManager.SearchPathDirectory) -> URL? {
        do {
            return try FileManager.default.url(for: searchPathDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            debugPrint("Failed to get URL for directory \(searchPathDirectory): \(error.localizedDescription)")
            return nil
        }
    }

    public static func temp(id: String? = nil, ext: String) -> String? {
        let name = id ?? UUID().uuidString
        let file = "\(name).\(ext)"
        return DirUtil.cache(file)
    }

    public static func exist(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    public static func remove(_ path: String) {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
        } catch {
            debugPrint("Failed to remove item at \(path): \(error.localizedDescription)")
        }
    }

    public static func copy(from source: String, to dest: String, _ overwrite: Bool) {
        if overwrite { remove(dest) }
        if !exist(dest) {
            do {
                try FileManager.default.copyItem(atPath: source, toPath: dest)
            } catch {
                debugPrint("Failed to copy item from \(source) to \(dest): \(error.localizedDescription)")
            }
        }
    }

    public static func created(_ path: String) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.creationDate] as? Date
        } catch {
            debugPrint("Failed to get creation date of \(path): \(error.localizedDescription)")
            return nil
        }
    }

    public static func modified(_ path: String) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            debugPrint("Failed to get modification date of \(path): \(error.localizedDescription)")
            return nil
        }
    }

    public static func size(_ path: String) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            debugPrint("Failed to get size of \(path): \(error.localizedDescription)")
            return nil
        }
    }

    public static func diskFree() -> Int64? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            print("Failed to get document directory path")
            return nil
        }

        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            return attributes[.systemFreeSize] as? Int64
        } catch {
            print("Failed to get disk free space: \(error.localizedDescription)")
            return nil
        }
    }

    public static func getURL(for directory: FileManager.SearchPathDirectory) -> URL? {
        FileManager.default.urls(for: directory, in: .userDomainMask).first
    }

    public static func fileExists(_ fileName: String, in directory: FileManager.SearchPathDirectory) -> Bool {
        guard let directoryURL = getURL(for: directory) else { return false }
        let url = directoryURL.appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }

    public static func convert(remoteURL: URL, directory: FileManager.SearchPathDirectory = .documentDirectory) -> URL? {
        guard let directoryURL = getURL(for: directory) else { return nil }
        return directoryURL.appendingPathComponent(remoteURL.lastPathComponent)
    }
}
