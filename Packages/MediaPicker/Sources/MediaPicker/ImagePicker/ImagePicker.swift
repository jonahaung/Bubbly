import SwiftUI
import PhotosUI

public struct ImagePickerItem: Sendable, Hashable, Identifiable {
	public let id: String
	public let image: UIImage

	public init(id: String, image: UIImage) {
		self.id = id
		self.image = image
	}

}
public struct ImagePicker<Content: View>: View, @unchecked Sendable {

	@State private var viewModel: ImagePickerViewModel
	@ViewBuilder private let content: () -> Content

	public init(_ selection: Binding<[SelectedPhoto]>, content: @escaping () -> Content) {
		self.content = content
		viewModel = .init(selection: selection)
	}
	public var body: some View {
		PhotosPicker(
			selection: viewModel.photosPickerSelection,
			selectionBehavior: .continuousAndOrdered,
			matching: .images,
			preferredItemEncoding: .current,
			photoLibrary: .shared()
		) {
			if viewModel.selection.wrappedValue.isEmpty {
				content()
			} else {
				ZStack {
					ForEach(viewModel.selection.wrappedValue) { each in

						if let result = viewModel.processedPhotos[each.id] {
							Image(uiImage: result.uiImage)
								.resizable()
								.scaledToFit()
						} else {
							ProgressView().controlSize(.mini)
								.task {
									await viewModel.loadPhoto(each)
								}
						}
					}
				}
			}

		}
		.photosPickerStyle(.presentation)
	}
}

@MainActor
@Observable
public final class InlinePhotoPickerViewModel {

	public var attachments: Binding<[ImageAttachment]>
	var selection: [PhotosPickerItem] {
		get {
			attachments.wrappedValue.map { $0.pickerItem }
		}
		set {
			self.attachments.wrappedValue = newValue.map { .init($0) }
		}
	}
	public init(attachments: Binding<[ImageAttachment]>) {
		self._attachments = attachments
		if !cachedSelection.isEmpty {
			attachments.wrappedValue = cachedSelection.map { value in
				ImageAttachment(itemIdentifier: value)
			}
		}
	}
	var processedPhotos = [ImageAttachment.ID: UIImage]()
	var invalidPhotos: [ImageAttachment.ID] = []

	func loadPhoto(_ item: ImageAttachment) async {
		var data: Data? = try? await item.loadTransferable(type: Data.self)

		if let cachedData = getCachedData(for: item.id) { data = cachedData }

		guard let data else { return }
		processedPhotos[item.id] = UIImage(data: data)

		cacheData(item.id, data)
	}

	func processAllPhotos() async {
		        await withTaskGroup { [self] group in
					for item in attachments.wrappedValue {
						guard processedPhotos[item.id] == nil else { continue }
						group.addTask { [self] in
		                    let data = await getData(for: item)
							let photo = UIImage(data: data)
							return (item.identifier, photo)
		                }
		            }

		            for await result in group {
						processedPhotos[result.0] = result.1
		            }
		        }
	}

	@concurrent
	func getData(for item: ImageAttachment) async -> Data {
		var data = try? await item.loadTransferable(type: Data.self)
		if let cachedData = await getCachedData(for: item.id) { data = cachedData }
		await cacheData(item.id, data!, updateState: false)
		return data!
	}

	func getCachedData(for id: ImageAttachment.ID) -> Data? {
		if cachedSelection.contains(where: { $0 == id }) {
			try? Data(contentsOf: cachedDirectory.appendingPathComponent("\(id)"))
		} else { nil }
	}

	func cacheData(_ id: ImageAttachment.ID, _ data: Data, updateState: Bool = true) {
		if updateState {
			updateProcessedPhotos()
			updateInvalidPhotos(for: id)
		}

		if !cachedSelection.contains(where: { $0 == id }) {
			cachedSelection.append(id)
			let url = cachedDirectory.appendingPathComponent("\(id)")
			try! data.write(to: url)
		}
	}

	var cachedSelection: [ImageAttachment.ID] {
		get {
			UserDefaults.standard.array(
				forKey: "cachedSelection"
			) as? [ImageAttachment.ID] ?? []
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "cachedSelection")
		}
	}

	private func updateProcessedPhotos() {
		processedPhotos = processedPhotos.filter { element in
			attachments.contains(where: { $0.id == element.key })
		}
	}

	private func updateInvalidPhotos(for id: ImageAttachment.ID) {
		if processedPhotos[id] == nil {
			invalidPhotos.append(id)
		}
	}

	private var cachedDirectory: URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

}
