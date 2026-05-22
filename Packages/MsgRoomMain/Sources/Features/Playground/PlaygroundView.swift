// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

// MARK: - PlaygroundView

struct PlaygroundView: View {
    @State private var viewModel: PlaygroundViewModel = .init()

    @State private var showModal = false
    @State private var searchText = ""
    @State private var text = ""
    @State private var fontName = ""

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
            Text(fontName)
            Button("Font Picker") {
                Router.shared.presentModel(.view(node: NavigationStack{ FontPicker(selection:$fontName) }.opaqueView()))
            }
    
            Button("System Sounds") {
                Router.shared.presentModel(.view(node: SystemSoundTesterView().opaqueView()))
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
            Spacer()
            Button("Submit") {
                Task {
                    await viewModel.send(.submit)
                }
            }
            
            Text(Lorem.paragraphs(8))
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
        .font(.custom(fontName, size: UIFont.labelFontSize))
        .task {
            await viewModel.send(.appear)
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
    }
}

// MARK: - ExpandingTextEditor

struct ExpandingTextEditor: View {
    @Binding var text: String

    let maxLines: Int
    let font: Font

    @State private var measuredHeight: CGFloat = 0

    init(
        text: Binding<String>,
        maxLines: Int = 5,
        font: Font = .body,
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
