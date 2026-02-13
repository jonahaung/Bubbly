import SwiftUI

/// Result display component
public struct ResultDisplay: View {
	public let result: String
	public let isSuccess: Bool
	@State private var isCopied = false
	@Environment(\.dismiss) private var dismiss

	public init(result: String, isSuccess: Bool) {
		self.result = result
		self.isSuccess = isSuccess
	}

	public var body: some View {
		VStack {
			Text(.init(result))
				.font(.title)
				.textSelection(.enabled)
		}
		.padding()
		.navigationTitle("Result")
	}
}
