//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct PickedPhoto: Transferable, Sendable, Hashable {
    public let uiImage: UIImage
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw PhotoPickerError.importFailed
            }
            return PickedPhoto(uiImage: uiImage)
        }
    }
}
