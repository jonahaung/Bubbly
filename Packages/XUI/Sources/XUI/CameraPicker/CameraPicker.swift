//
//  CameraPicker.swift
//  XUI
//
//  Created by Aung Ko Min on 5/4/26.
//

import SwiftUI
import AVFoundation

public extension CameraPicker {
    typealias Device = UIImagePickerController.CameraDevice
    typealias CaptureMode = UIImagePickerController.CameraCaptureMode
    typealias FlashMode = UIImagePickerController.CameraFlashMode
}

public struct CameraPicker: View {

	@State var selection: (any CameraPickerItem)?
    @State private var imagePickerControllerError: LocalizedError?
    @State private var showingCamera = false

    let allowesEditing: Bool
    let preferredMediaTypes: Set<CameraPickerMediaType>
    let cameraDevice: Device
    let preferredCaptureMode: CaptureMode
    let flashMode: FlashMode
	let onPicked: (any CameraPickerItem) -> Void

    public init(
        allowsEditing: Bool = false,
        preferredMediaTypes: Set<CameraPickerMediaType> = [.image],
        cameraDevice: Device = .rear,
        preferredCaptureMode: CaptureMode = .photo,
        flashMode: FlashMode = .auto,
		onPicked: @escaping (any CameraPickerItem) -> Void
    ) {
        self.allowesEditing = allowsEditing
        self.preferredMediaTypes = preferredMediaTypes
        self.cameraDevice = cameraDevice
        self.preferredCaptureMode = preferredCaptureMode
        self.flashMode = flashMode
		self.onPicked = onPicked
    }

    public var body: some View {
		UIImagePickerControllerRepresentation(
			selection: Self.arrayBindingFrom(optionalBinding: $selection),
			error: $imagePickerControllerError,
			allowsEditing: allowesEditing,
			preferredMediaTypes: preferredMediaTypes,
			cameraDevice: cameraDevice,
			preferredCaptureMode: preferredCaptureMode,
			flashMode: flashMode
		)
		.ignoresSafeArea()
		.onChange(of: selection?.id) { oldValue, newValue in
			if let item = selection {
				onPicked(item)
			}
		}
    }
}

extension CameraPicker {
    private static func arrayBindingFrom(
        optionalBinding: Binding<(any CameraPickerItem)?>
    ) -> Binding<[any CameraPickerItem]> {
        Binding<[any CameraPickerItem]> {
            if let item = optionalBinding.wrappedValue {
                return [item]
            } else {
                return []
            }
        } set: { newItems in
            if let item = newItems.first {
                optionalBinding.wrappedValue = item
            } else {
                optionalBinding.wrappedValue = nil
            }
        }
    }
}
