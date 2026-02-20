import Services
import SwiftUI
import XUI

struct PlaygroundView: View {
	@State private var viewModel = PlaygroundViewModel()

	@State private var showModal = false
	let text = Lorem.random()
	@State private var fontName = ""
	@State private var searchText = ""

	var body: some View {
		VStack(spacing: 16) {
			if viewModel.state.isLoading {
				ProgressView()
			}

			if let error = viewModel.state.error {
				Text(error)
					.foregroundStyle(.red)
			}

			Button("Show modal") {
				showModal = true
			}
			Button("Font Picker") {
				Router.shared.presnetModel(.view(FontPicker(selection: $fontName).opaqueView()))
			}
			Button("Markdown View") {
				Router.shared.presnetModel(.view(MarkdownView.ExampleView().opaqueView()))
			}
			Button("System Sounds") {
				Router.shared.presnetModel(.view(SystemSoundTesterView().opaqueView()))
			}
			Button("Show Toast") {
				ToastPresenter.show(allowsBackgroundTap: true) {
					Text(Lorem.random())
				} action: {
					print("tapped")
				}
			}
			Text("Example View").tapToPush {
				ExampleView1()
			}
			Button("Show Loading") {
				Loading.show(true)
			}
			Label(text, systemImage: "bubble.right")
			Spacer()
			Button("Submit") {
				Task {
					await viewModel.send(.submit)
				}
			}
		}
		.padding()
		.flexible(.all)
		.navigationTitle("Playground")
		.searchable(text: $searchText)
		.overlay {
			if showModal {
				ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
					Text(Lorem.random())
						.padding()
						.background(.bar, in: .rect)
						.colorScheme(.dark)
				} onClose: {
					showModal = false
				}
			}
		}
		.task {
			await viewModel.send(.appear)
		}
		.refreshable {
			await viewModel.send(.refresh)
		}
	}
}
