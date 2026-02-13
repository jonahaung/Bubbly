import Core
import Database
import ImageLoader
import Services
import SwiftUI
import VideoLoader
import XUI

struct ImageUploadingLayer: View {
	let attachment: Attachment
	let url: URL
	let conversationID: String
	let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

	@Environment(\.viewIsVisible) private var viewIsVisible
	@State private var progress: ImageTask.Progress?
	@State private var uploading = false
	private let uploader = ImageUploadingService()

	var body: some View {
		ZStack(alignment: .center) {
			if let progress {
				Gauge(value: progress.fraction) {
					Text("\(progress.fraction)")
				}
				.gaugeStyle(.accessoryCircularCapacity)
				.tint(Color.white.gradient)
				.frame(square: 150)
				.animation(.default, value: progress.completed)
			}
		}
		.task(id: viewIsVisible) {
			if viewIsVisible {
				await startUpload()
			}
		}
	}

	private func startUpload() async {
		guard !uploading else {
			return
		}
		uploading = true
		let attachmentID = attachment.uid
		let conID = conversationID

		do {
			let url = try await uploader.uploadFile(
				url,
				to: .conversation(conID: conID, attachmentID: attachmentID)
			) { progress in
				Task { @MainActor in
					if let progress {
						if progress.completedUnitCount == progress.totalUnitCount {
							self.progress = nil
						} else {
							self.progress = .init(
								completed: progress.completedUnitCount,
								total: progress.totalUnitCount
							)
						}
					}
				}
			}
			await MainActor.run {
				var newValue = attachment
				newValue.url = url.absoluteString
				newValue.attachMentTypeRaw = AttachMentType.image.rawValue
				onCompleteUpload?(newValue)
			}
		} catch {
			log(error)
		}
	}
}
