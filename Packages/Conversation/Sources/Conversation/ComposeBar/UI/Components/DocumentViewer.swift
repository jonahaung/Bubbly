import QuickLook
import SwiftUI

struct DocumentViewer: UIViewControllerRepresentable {
    let urls: [URL]

    func makeCoordinator() -> DocumentViewerCoordinator {
        DocumentViewerCoordinator(urls: urls)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ controller: QLPreviewController,
        context: Context
    ) {
        context.coordinator.update(urls: urls)
        controller.reloadData()
    }

    static func dismantleUIViewController(
        _ controller: QLPreviewController,
        coordinator: DocumentViewerCoordinator
    ) {
        controller.dataSource = nil
        coordinator.stopAccessingResources()
    }
}
