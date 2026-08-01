// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

struct PlaygroundView: View {
    
    @State private var searchText = ""
    @State private var text = ""
    @State private var fontName = ""

    var body: some View {
        List {
            
            Section {
                Button("Font Picker : \(fontName)") {
                    Router.shared.presentModel(.view(node: NavigationStack{ FontPicker(selection:$fontName) }.opaqueView()))
                }
                Button("Show Toast") {
                    ToastPresenter.show(Lorem.random())
                }
            }
            Section("Rich Text") {
                let rich = MarkdownFormatter().richText(for: markdownTestData)
                Text(rich)
            }
            Section("Markdown Text") {
                let rich = MarkdownFormatter().markdownText(for: markdownTestData)
                Text(rich)
            }
            Section("Custom Markdown") {
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
            }
        }
        .navigationTitle(Self.defaultTitle)
        .searchable(text: $searchText)
        .font(.custom(fontName, size: UIFont.labelFontSize))
    }
}

let markdownTestData = """
# Exploring SwiftUI

SwiftUI helps you build modern interfaces using **declarative syntax**, *reusable views*, and `@State`-driven updates. Learn more at https://developer.apple.com/xcode/swiftui/.

---

## Text Styles

This paragraph combines **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `monospaced text`.

You can also include special characters:

- Ampersand: &
- Less than: <
- Greater than: >
- Quotation marks: "Hello"
- Emoji: 🚀 🎨 📱

---

## Development Checklist

- [x] Create the project
- [x] Define the data model
- [ ] Build the user interface
- [ ] Add accessibility labels
- [ ] Write unit tests

### Priorities

1. Correctness
2. Accessibility
3. Performance
4. Maintainability

---

## Nested Content

- Apple Platforms
  - iOS
  - iPadOS
  - macOS
    - AppKit
    - SwiftUI
  - watchOS
  - visionOS
- Development Tools
  - Xcode
  - Instruments
  - Swift Package Manager

---

## Quotation

> Simplicity is achieved by removing everything that does not contribute to the experience.
>
> A good interface should remain clear, predictable, and accessible.

---

## Sample Table

| Feature | Framework | Status |
| --- | --- | --- |
| User interface | SwiftUI | Ready |
| Persistence | SwiftData | In progress |
| Networking | URLSession | Ready |
| Testing | Swift Testing | Planned |

---

## Swift Example

```swift
import SwiftUI

struct ProfileView: View {
    let name: String
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle)

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(isOnline ? "Online" : "Offline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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

#Preview("Modifier") {
    @Previewable @State var fontSize: CGFloat = 16
    @Previewable @State var fontWeightIndex = 3

    @Previewable @State var text = Color.yellow
    @Previewable @State var background = Color.orange

    let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]

    let fontWeight = weights[fontWeightIndex % weights.count]

    ScrollView {
        let sample = HStack {
            Image(systemName: "circle.fill").fontWeight(.regular)

            ZStack {
                Text("Hi!").fontWeight(.black).hidden()
                Text("Hi!")
            }
        }
        .animation(.default, value: fontWeight)

        ForEach([Color.white, .orange, .blue, .black, .gray], id: \.self) { background in
            HStack {
                let colors = [Color.green, .yellow, .orange, .pink, .purple, .blue, .gray]
                ForEach(colors, id: \.self) { text in
                    Text("Hi")
                        .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: background, fontSize: fontSize, weight: fontWeight))
                        .fixedSize()
                }
            }
            .padding()
            .background(background, in: .rect(cornerRadius: 8))
            .font(.system(size: fontSize, weight: fontWeight))
        }

        if #available(iOS 26.0, *) {
            ForEach([Color.white, .orange, .black], id: \.self) { background in
                HStack {
                    let colors = [Color.green, .yellow, .orange, .pink, .purple, .blue]
                    ForEach(colors, id: \.self) { text in
                        Text("Hi")
                            .foregroundStyle(text.minimumContrast(over: background))
                    }
                }
                .padding()
                .background(background, in: .rect(cornerRadius: 8))
                .font(.system(size: fontSize, weight: fontWeight))
            }
        }

        VStack {
            sample
                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: .white, fontSize: fontSize, weight: fontWeight))
                .foregroundStyle(text)
                .padding(32)
                .background(.white)

            sample
                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: background, fontSize: fontSize, weight: fontWeight))
                .foregroundStyle(text)
                .padding(32)
                .background(background)

            sample
                .modifier(APCADerivedForegroundColor(foregroundColor: text, backgroundColor: .black, fontSize: fontSize, weight: fontWeight))
                .foregroundStyle(text)
                .padding(32)
                .background(.black)
        }
        .font(.system(size: fontSize, weight: fontWeight))

        Spacer()
    }
    .safeAreaInset(edge: .top) {
        GroupBox {
            Grid {
                GridRow {
                    Label("Size", systemImage: "textformat.size")
                    Slider(value: $fontSize, in: 9 ... 160)
                        .padding(.leading)
                }

                GridRow {
                    Label("Weight", systemImage: "bold")

                    HStack {
                        Button("Previous", systemImage: "minus") {
                            fontWeightIndex -= 1
                        }

                        Group {
                            switch fontWeight {
                            case .ultraLight: Text("Ultra Light")
                            case .thin: Text("Thin")
                            case .light: Text("Light")
                            case .regular: Text("Regular")
                            case .medium: Text("Medium")
                            case .semibold: Text("Semibold")
                            case .bold: Text("Bold")
                            case .heavy: Text("Heavy")
                            case .black: Text("Black")
                            default: EmptyView()
                            }
                        }
                        .frame(maxWidth: 80)

                        Button("Next", systemImage: "plus") {
                            fontWeightIndex += 1
                        }
                    }
                    .padding(8)
                    .background(.ultraThickMaterial, in: .rect(cornerRadius: 4))
                    .labelStyle(.iconOnly)
                }

                GridRow {
                    HStack {}
                }
            }
        }
        .padding(.horizontal)

        Spacer().frame(height: 44)

    }
}
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
