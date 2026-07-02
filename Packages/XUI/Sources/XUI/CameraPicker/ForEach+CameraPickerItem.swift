//  ForEach+CameraPickerItem.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension ForEach where ID == UUID, Content: View, Data.Element == any CameraPickerItem {
    init(_ data: Data, @ViewBuilder content: @escaping (any CameraPickerItem) -> Content) {
        self.init(data, id: \.id, content: content)
    }
}
