
import SwiftUI
import Pow

public struct LoadingOverlay: View {
    public init() {}

    public var body: some View {
		LoadingIndicator(22)
			.transition(.movingParts.anvil)
    }
}
