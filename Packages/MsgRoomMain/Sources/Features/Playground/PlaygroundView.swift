// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

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
            Button("Show Toast") {
                ToastPresenter.show(allowsBackgroundTap: true) {
                    Text(Lorem.random())
                } action: {
                    print("tapped")
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
                let rich = MarkdownFormatter().richText(for: markdownTestData)
                
                Text(rich)
            }
            
            Text(Lorem.paragraphs(8))
        }
        .navigationTitle(Self.defaultTitle)
        .searchable(text: $searchText)
        .fullScreenCover(isPresented: $showModal, content: {
            ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
                Text(text)
                    .padding()
                    .background(.bar, in: .rect)
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
        "Hello, Aung Ko Min"
    }
}
"""

//#Preview("Over") {
//    @Previewable @State var a = Color.Resolved(red: 0.6, green: 0.3, blue: 0.4, opacity: 0.5)
//    @Previewable @State var b = Color.Resolved(red: 0.2, green: 0.2, blue: 1.0, opacity: 0.2)
//
//    HStack(spacing: 0) {
//        Color(a.over(b).over(.init(red: 1, green: 1, blue: 1)))
//
//        Color(a).background(Color(b), in: .rect).background(.white)
//    }
//}
//
//#Preview("Test Values") {
//    let rgb2color: (UInt) -> Color.Resolved = { rgb in
//        Color.Resolved(
//            red: Float((rgb >> 16) & 0xFF) / 255,
//            green: Float((rgb >> 8) & 0xFF) / 255,
//            blue: Float((rgb >> 0) & 0xFF) / 255
//        )
//    }
//
//    let example: (Color.Resolved, Color.Resolved) -> some View = { a, b in
//        HStack {
//            Group {
//                Color(a)
//                Color(b)
//                VStack(alignment: .trailing) {
//                    Text(Color.Resolved.APCAContrast(text: a, background: b), format: .number)
//                    Text(Color.Resolved.APCAContrast(text: b, background: a), format: .number)
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .aspectRatio(1, contentMode: .fit)
//        }
//        .monospacedDigit()
//    }
//
//    example(rgb2color(0x888888), rgb2color(0xFFFFFF))
//
//    example(rgb2color(0x000000), rgb2color(0xAAAAAA))
//
//    example(rgb2color(0x112233), rgb2color(0xDDEEFF))
//
//    example(rgb2color(0x112233), rgb2color(0x444444))
//}

//#Preview("Modifier") {
//    @Previewable @State var fontSize: CGFloat = 16
//    @Previewable @State var fontWeightIndex = 3
//
//    @Previewable @State var text = Color.yellow
//    @Previewable @State var background = Color.orange
//
//    let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
//
//    let fontWeight = weights[fontWeightIndex % weights.count]
//
//    ScrollView {
//        let sample = HStack {
//            Image(systemName: "circle.fill").fontWeight(.regular)
//
//            ZStack {
//                Text("Hi!").fontWeight(.black).hidden()
//                Text("Hi!")
//            }
//        }
//        .animation(.default, value: fontWeight)
//
//        ForEach([Color.white, .orange, .black], id: \.self) { background in
//            HStack {
//                let colors = [Color.green, .yellow, .orange, .pink, .purple, .blue]
//                ForEach(colors, id: \.self) { text in
//                    Text("Hi")
//                        .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: background, fontSize: fontSize, weight: fontWeight))
//                        .fixedSize()
//                }
//            }
//            .padding()
//            .background(background, in: .rect(cornerRadius: 8))
//            .font(.system(size: fontSize, weight: fontWeight))
//        }
//
//        if #available(iOS 26.0, *) {
//            ForEach([Color.white, .orange, .black], id: \.self) { background in
//                HStack {
//                    let colors = [Color.green, .yellow, .orange, .pink, .purple, .blue]
//                    ForEach(colors, id: \.self) { text in
//                        Text("Hi")
//                            .foregroundStyle(text.minimumContrast(over: background))
//                    }
//                }
//                .padding()
//                .background(background, in: .rect(cornerRadius: 8))
//                .font(.system(size: fontSize, weight: fontWeight))
//            }
//        }
//
//        VStack {
//            sample
//                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: .white, fontSize: fontSize, weight: fontWeight))
//                .foregroundStyle(text)
//                .padding(32)
//                .background(.white)
//
//            sample
//                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: background, fontSize: fontSize, weight: fontWeight))
//                .foregroundStyle(text)
//                .padding(32)
//                .background(background)
//
//            sample
//                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: .black, fontSize: fontSize, weight: fontWeight))
//                .foregroundStyle(text)
//                .padding(32)
//                .background(.black)
//        }
//        .font(.system(size: fontSize, weight: fontWeight))
//
//        Spacer()
//    }
//    .safeAreaInset(edge: .top) {
//        GroupBox {
//            Grid {
//                GridRow {
//                    Label("Size", systemImage: "textformat.size")
//                    Slider(value: $fontSize, in: 9 ... 160)
//                        .padding(.leading)
//                }
//
//                GridRow {
//                    Label("Weight", systemImage: "bold")
//
//                    HStack {
//                        Button("Previous", systemImage: "minus") {
//                            fontWeightIndex -= 1
//                        }
//
//                        Group {
//                            switch fontWeight {
//                            case .ultraLight: Text("Ultra Light")
//                            case .thin: Text("Thin")
//                            case .light: Text("Light")
//                            case .regular: Text("Regular")
//                            case .medium: Text("Medium")
//                            case .semibold: Text("Semibold")
//                            case .bold: Text("Bold")
//                            case .heavy: Text("Heavy")
//                            case .black: Text("Black")
//                            default: EmptyView()
//                            }
//                        }
//                        .frame(maxWidth: 80)
//
//                        Button("Next", systemImage: "plus") {
//                            fontWeightIndex += 1
//                        }
//                    }
//                    .padding(8)
//                    .background(.ultraThickMaterial, in: .rect(cornerRadius: 4))
//                    .labelStyle(.iconOnly)
//                }
//
//                GridRow {
//                    HStack {}
//                }
//            }
//        }
//        .padding(.horizontal)
//
//        Spacer().frame(height: 44)
//
//    }
//}
//
//@available(iOS 18.0, *)
//#Preview("ShapeStyle") {
//    @Previewable @State var foreground = Color.red
//    @Previewable @State var background = Color.blue
//    @Previewable @State var contrast: Float = 90
//
//    GroupBox {
//        Slider(value: $contrast, in: 0 ... 100)
//
//        HStack {
//            ColorPicker("Foreground", selection: $foreground)
//            ColorPicker("Background", selection: $background)
//        }
//    }
//    .padding()
//
//    Circle()
//        .fill(foreground.minimumContrast(contrast, over: background))
//        .frame(width: 44, height: 44)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(background)
//}

//#Preview("Interpolating Font.Weight") {
//    @Previewable @State var weight: CGFloat = 0
//
//    GroupBox {
//        Slider(value: $weight, in: -1 ... 1)
//
//        Text("A")
//            .font(.system(size: 100, weight: .init(value: weight)))
//    }
//    .padding()
//}
//
//@available(iOS 26.0, *)
//#Preview("Readme") {
//    HStack {
//        Text("Hello World")
//
//        Text("What's Up?!")
//            .fontWeight(.black)
//    }
//    .foregroundStyle(Color.pink.minimumContrast(over: Color.primary))
//    .padding()
//    .background(.primary)
//}
