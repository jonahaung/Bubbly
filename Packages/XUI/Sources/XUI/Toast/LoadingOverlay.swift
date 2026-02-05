// LoadingOverlay.swift (in XUI)
import SwiftUI

import SwiftUI

public struct LoadingOverlay: View {
	public init() {}

	public var body: some View {
		ZStack(alignment: .top) {
			Color.clear
				.contentShape(ContainerRelativeShape())
				.backgroundExtensionEffect()
				.onTapGesture { Loading.show(false) }
			LoadingIndicator(22)
		}
		.presentationBackground(.clear)
	}
}
