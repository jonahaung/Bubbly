//
//  ForEach+CameraPickerItem.swift
//  XUI
//
//  Created by Aung Ko Min on 5/4/26.
//

import SwiftUI

public extension ForEach where ID == UUID, Content: View, Data.Element == any CameraPickerItem {
	init(_ data: Data, @ViewBuilder content: @escaping (any CameraPickerItem) -> Content) {
		self.init(data, id: \.id, content: content)
	}
}
