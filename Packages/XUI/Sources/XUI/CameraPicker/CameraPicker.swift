//  CameraPicker.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import AVFoundation

public extension CameraPicker {
    typealias Device = UIImagePickerController.CameraDevice
    typealias CaptureMode = UIImagePickerController.CameraCaptureMode
    typealias FlashMode = UIImagePickerController.CameraFlashMode
}

public struct CameraPicker: View {

    @State private var selection: (any CameraPickerItem)?
    @State private var imagePickerControllerError: LocalizedError?
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
        allowesEditing = allowsEditing
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
        .onChange(of: selection?.id) { _, _ in
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
                [item]
            } else {
                []
            }
        } set: { newItems in
            optionalBinding.wrappedValue = if let item = newItems.first {
                item
            } else {
                nil
            }
        }
    }
}
