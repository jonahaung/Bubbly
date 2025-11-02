import SwiftUI

@MainActor
public struct FolderListView: View {

	@State private var folder: Folder

	public init(folder: Folder) {
		self._folder = State(initialValue: folder)
	}

	public var body: some View {
		List {
			// MARK: - Subfolders
			if folder.subfolders.count() > 0 {
				Section("Folders") {
					ForEach(Array(folder.subfolders)) { subFolder in
						FolderListRow(folder: subFolder)
					}
					.onDelete(perform: deleteFolders)
				}
			}

			// MARK: - Files
			if folder.files.count() > 0 {
				Section("Files") {
					ForEach(Array(folder.files)) { file in
						FileRow(file: file)
					}
					.onDelete(perform: deleteFiles)
				}
			}
		}
		.navigationTitle(folder.name)
	}

	// MARK: - Delete handlers
	private func deleteFolders(at offsets: IndexSet) {
		for index in offsets {
			let subFolder = Array(folder.subfolders)[index]
			try? subFolder.delete()
		}
	}

	private func deleteFiles(at offsets: IndexSet) {
		for index in offsets {
			let file = Array(folder.files)[index]
			try? file.delete()
		}
	}
}

// MARK: - Folder Row
private struct FolderListRow: View {
	let folder: Folder

	var body: some View {
		NavigationLink {
			FolderListView(folder: folder)
		} label: {
			Label(folder.name, systemSymbol: .folderFill)
				.badge(folder.subfolders.count() + folder.files.count())
		}
	}
}

// MARK: - File Row
private struct FileRow: View {
	let file: File

	var body: some View {
		NavigationLink {
			FilePreviewView(file: file)
		} label: {
			Label(file.nameExcludingExtension, systemSymbol: .docText)
		}
	}
}

// MARK: - File Preview
private struct FilePreviewView: View {
	let file: File

	var body: some View {
		Group {
			if let image = loadImage() {
				image
					.resizable()
					.scaledToFit()
					.padding()
			} else {
				if let string = try? file.readAsString() {
					Text(string)
						.padding()
				} else if let int = try? file.readAsInt() {
					Text("\(int)")
						.padding()
				} else {
					Text(file.description)
				}
			}
		}
		.navigationTitle(file.nameExcludingExtension)
	}

	private func loadImage() -> Image? {
		guard let data = try? file.read(),
			  let ui = UIImage(data: data) else { return nil }
		return Image(uiImage: ui)
	}
}
