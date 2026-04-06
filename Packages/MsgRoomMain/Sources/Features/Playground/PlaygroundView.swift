//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Services
import SwiftUI
import XUI

struct PlaygroundView: View {
    @State private var viewModel = PlaygroundViewModel()

    @State private var showModal = false
    @State private var fontName = ""
    @State private var searchText = ""
    @State private var text = ""
    var body: some View {
        List {
			if viewModel.state.isLoading {
				ProgressView()
			}

			if let error = viewModel.state.error {
				Text(error)
					.foregroundStyle(.red)
			}

			Button("Show modal") {
				text = Lorem.random()
				showModal = true
			}
			Button("Font Picker") {
//				Router.shared.presentModel(.view(FontPicker(selection: $fontName).opaqueView()))
			}
			Button("Markdown View") {
//				Router.shared.presentModel(.view(MarkdownView.ExampleView().opaqueView()))
			}
			Button("System Sounds") {
//				Router.shared.presentModel(.view(SystemSoundTesterView().opaqueView()))
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
		.navigationTitle(Self.defaultTitle)
        .searchable(text: $searchText)
        .overlay {
            if showModal {
				ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
					Text(text)
                        .padding()
                        .background(.bar, in: .rect)
						.foregroundStyle(Color.white)
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

struct ExpandingTextEditor: View {

    @Binding var text: String

    let maxLines: Int
    let font: Font

    @State private var measuredHeight: CGFloat = 0

    init(
        text: Binding<String>,
        maxLines: Int = 5,
        font: Font = .body
    ) {
        _text = text
        self.maxLines = maxLines
        self.font = font
    }

    var body: some View {

        ZStack(alignment: .topLeading) {

            TextEditor(text: $text)
                .font(font)
                .frame(height: clampedHeight)
                .background(.fill)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            //			// Invisible measuring text
            //			Text(text.isEmpty ? " " : text)
            //				.font(font)
            //				.lineLimit(maxLines)
            //				.padding(.vertical, 4)
            //				.background(
            //					GeometryReader { proxy in
            //						Color.clear
            //							.onAppear {
            //								measuredHeight = proxy.size.height
            //							}
            //							.onChange(of: text) { _ in
            //								measuredHeight = proxy.size.height
            //							}
            //					}
            //				)
            //				.hidden()
        }
        .padding(.bottom)
    }

    private var lineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    private var minHeight: CGFloat {
        lineHeight + 12
    }

    private var maxHeight: CGFloat {
        lineHeight * CGFloat(maxLines) + 24
    }

    private var clampedHeight: CGFloat {
        min(max(measuredHeight, minHeight), maxHeight)
    }
}
