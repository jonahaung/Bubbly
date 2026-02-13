import PhotosUI
import SwiftUI

public struct PhotoPickerButton<Content: View>: View {
	@State private var viewModel: PhotoPickerViewModel
	private let size: CGFloat
	private let clipShape: AnyShape
	private let onTap: (() -> Void)?
	private let pickerButtonSize: CGFloat
	@ViewBuilder private var content: () -> Content
	@Binding private var pickedPhoto: PickedPhoto?

	// MARK: - Init

	public init(pickedPhoto: Binding<PickedPhoto?>,
	            size: CGFloat = 100,
	            clipShape: any Shape = Circle(),
	            @ViewBuilder content: @escaping () -> Content,
	            onTap: (() -> Void)? = nil)
	{
		_viewModel = State(
			wrappedValue: PhotoPickerViewModel(pickedPhoto.wrappedValue)
		)
		self.size = size
		self.clipShape = AnyShape(clipShape)
		self.onTap = onTap
		pickerButtonSize = size / 5
		self.content = content
		_pickedPhoto = pickedPhoto
	}

	// MARK: - Body

	public var body: some View {
		contentView
			.clipShape(clipShape)
			.frame(width: size, height: size)
			.onTapGesture { onTap?() }
			.overlay(alignment: .bottomTrailing) { overlayControl }
			.onChange(of: viewModel.pickedPhoto) { _, newValue in
				if newValue != pickedPhoto {
					pickedPhoto = newValue
				}
			}
			.onChange(of: pickedPhoto) { oldValue, newValue in
				if oldValue != nil, newValue == nil {
					viewModel.imageSelection = nil
				}
			}
	}

	// MARK: - Content

	@ViewBuilder
	private var contentView: some View {
		switch viewModel.imageState {
		case .empty:
			content()
		case .loading:
			ProgressView().controlSize(.regular)
		case let .success(content):
			Image(uiImage: content)
				.resizable()
				.scaledToFill()
		case .failure:
			Image(systemName: "exclamationmark.circle.fill")
				.resizable()
				.scaledToFit()
		}
	}

	// MARK: - Overlay

	private var overlayControl: some View {
		Group {
			if viewModel.imageState == .empty {
				PhotosPicker(
					selection: $viewModel.imageSelection,
					matching: .images,
					photoLibrary: .shared()
				) {
					Image(systemName: "pencil.circle.fill")
						.resizable()
				}
			} else {
				Button {
					viewModel.imageSelection = nil
				} label: {
					Image(systemName: "minus.circle.fill")
						.resizable()
				}
			}
		}
		.fontWeight(.light)
		.symbolRenderingMode(.multicolor)
		.frame(width: pickerButtonSize, height: pickerButtonSize)
		.padding(pickerButtonSize / 4)
		.buttonStyle(.borderless)
	}
}
