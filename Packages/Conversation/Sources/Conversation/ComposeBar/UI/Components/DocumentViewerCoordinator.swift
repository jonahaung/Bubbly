import Foundation
@preconcurrency import QuickLook

@MainActor
final class DocumentViewerCoordinator: NSObject, QLPreviewControllerDataSource {
    private var urls: [URL] = []
    private var accessedURLs: [URL] = []

    init(urls: [URL]) {
        super.init()
        update(urls: urls)
    }

    func update(urls: [URL]) {
        guard self.urls != urls else {
            return
        }

        stopAccessingResources()
        self.urls = urls
        accessedURLs = urls.filter { $0.startAccessingSecurityScopedResource() }
    }

    func stopAccessingResources() {
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        accessedURLs.removeAll()
    }

    nonisolated func numberOfPreviewItems(
        in controller: QLPreviewController
    ) -> Int {
        MainActor.assumeIsolated {
            urls.count
        }
    }

    nonisolated func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> any QLPreviewItem {
        MainActor.assumeIsolated {
            guard urls.indices.contains(index) else {
                return URL(fileURLWithPath: "") as NSURL
            }
            return urls[index] as NSURL
        }
    }
}
