import Foundation

actor LibraryPickerFileWriter {
    func write(_ data: Data, pathExtension: String) throws -> URL {
        try Task.checkCancellation()
        let url = URL.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension(pathExtension)
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            try Task.checkCancellation()
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    func removeFiles(at urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
