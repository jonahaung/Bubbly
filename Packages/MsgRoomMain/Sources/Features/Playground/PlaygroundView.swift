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
                withTransaction(\.disablesAnimations, true) {
                    showModal = true
                }
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
            Text("Reduction").tapToPush {
                RedactionExamples()
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
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(MarkdownParser.parse(markdownTestData), id: \.self) { item in
                    switch item {
                    case let .heading(level, text):
                        Text(text)
                            .font(.system(size: 18 + CGFloat((6 - min(level,6)) * 2), weight: .bold))
                            .padding(.vertical, 4)
                    case let .paragraph(text):
                        Text(.init(text))
                    case let .codeBlock(_, content):
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(5)
                    case let .listItem(_, text):
                        Text(.init("• " + text))
                    case let .orderedListItem(_, idx, text):
                        Text(.init("\(idx). " + text))
                    case let .blockquote(text):
                        Text(text)
                            .italic()
                            .padding(.leading, 16)
                            .border(.gray.opacity(0.4))
                    case .horizontalRule:
                        Divider()
                    case let .mention(username):
                        Text("@" + username)
                            .foregroundColor(.red)
                    case let .hashtag(topic):
                        Text("#" + topic)
                            .foregroundColor(.blue)
                    case let .unknown(text):
                        Text(text)
                    }
                }
            }
            
            Text(Lorem.paragraphs(8))
        }
        .navigationTitle(Self.defaultTitle)
        .searchable(text: $searchText)
        .fullScreenCover(isPresented: $showModal, content: {
            ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
                Text(text)
                    .padding()
                    .background(.regularMaterial, in: .rect)
                    .overlay {
                        Rectangle().strokeBorder(.primary, lineWidth: 1)
                    }
                    .colorScheme(.dark)

            }
            .presentationContentInteraction(.automatic)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(.clear)
        })
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

let name = "Aung Ko Min"

let markdownTestData = """
# Welcome to the Markdown Test

This is the first paragraph. It contains **bold text**, *italic text*, ***bold italic text***, and `inline code`. You can also test links such as https://www.example.com and email addresses like test@example.com.

---

## Lists and Formatting

This second paragraph contains a list:

- Apple
- Banana
- Orange
  - Nested item A
  - Nested item B

And an ordered list:

1. First item
2. Second item
3. Third item

You can also test ~~strikethrough~~ and > blockquotes.

> This is a blockquote.
> It spans multiple lines.
> Useful for testing rendering behavior.

---

## Code Examples

The third paragraph contains a Swift code block:

```swift
struct User {
    let id: Int
    let name: String

    func greeting() -> String {
        "Hello, \(name)"
    }
}
"""
struct RedactionExamples: View {
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: 200)
                Text("Title Placeholder")
                    .font(.title)
                Text("Description text that will be replaced with shimmer effect")
                    .font(.body)
            }
            .customRedaction()
            .redacted(reason: isLoading ? .shimmer : [])
            
            Text("Profile Name")
                .font(.headline)
                .customRedaction(.init(shape: .roundedRectangle(4)))
                .redactedWithShimmer(when: isLoading)
            
            AvatarView()
                .customRedaction(.init(
                    shape: .circle,
                    animationDuration: 2.0,
                    shimmerColors: [.blue.opacity(0.2), .blue.opacity(0.5), .blue.opacity(0.2)]
                ))
                .redacted(reason: isLoading ? .shimmer : [])
            
            SensitiveDataView()
                .customRedaction()
                .redactedWithBlur(when: isLoading)
            
            Button("Toggle Loading") {
                isLoading.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct AvatarView: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 60, height: 60)
    }
}

struct SensitiveDataView: View {
    var body: some View {
        Text("Sensitive Information")
            .padding()
            .background(Color.yellow.opacity(0.3))
            .cornerRadius(8)
    }
}
