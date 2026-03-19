import SwiftUI

@available(iOS 26.0, *)
private struct MinimumContrastColorFont<Foreground: ShapeStyle, Background: ShapeStyle>: ShapeStyle where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
    var foreground: Foreground

    var background: Background

    init(foreground: Foreground, background: Background) {
        self.foreground = foreground
        self.background = background
    }

    func resolve(in environment: EnvironmentValues) -> Color {
        let t = foreground.resolve(in: environment)
        let b = background.resolve(in: environment)

        let targetColor = t.apcaLuminance > b.apcaLuminance ? Color.white : .black

        let font = (environment.font ?? Font.default).resolve(in: environment.fontResolutionContext)
        let pointSize = font.pointSize
        let weight = font.weight

        let target = Font.APCAContrastTarget(for: pointSize, weight: weight)

        return stride(from: 0, to: 1, by: 0.05)
            .lazy
            .map { fraction in
                Color(t).mix(with: targetColor, by: fraction)
            }
            .first { candidate in
                let candidate = candidate.resolve(in: environment)

                return abs(Color.Resolved.APCAContrast(text: candidate, background: b)) >= abs(target)
            } ?? targetColor
    }
}

@available(iOS 18.0, *)
private struct MinimumContrastColor<Foreground: ShapeStyle, Background: ShapeStyle>: ShapeStyle where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
    var foreground: Foreground

    var background: Background

    var minimumContrast: Float

    func resolve(in environment: EnvironmentValues) -> Color {
        let t = foreground.resolve(in: environment)
        let b = background.resolve(in: environment)

        let targetColor = t.apcaLuminance > b.apcaLuminance ? Color.white : .black

        return stride(from: 0, to: 1, by: 0.05)
            .lazy
            .map { fraction in
                Color(t).mix(with: targetColor, by: fraction)
            }
            .first { candidate in
                let candidate = candidate.resolve(in: environment)

                return abs(Color.Resolved.APCAContrast(text: candidate, background: b)) >= abs(minimumContrast)
            } ?? targetColor
    }
}

public extension ShapeStyle where Resolved == Color.Resolved {
    @available(iOS 18.0, *)
    func minimumContrast<Background: ShapeStyle>(_ contrast: Float, over background: Background) -> some ShapeStyle where Background.Resolved == Color.Resolved {
        MinimumContrastColor(foreground: self, background: background, minimumContrast: contrast)
    }

    @available(iOS 26.0, *)
    func minimumContrast<Background: ShapeStyle>(over background: Background) -> some ShapeStyle where Background.Resolved == Color.Resolved {
        MinimumContrastColorFont(foreground: self, background: background)
    }
}

@available(iOS 18.0, *)
struct APCADerivedForegroundColor: ViewModifier {
    @ScaledMetric var fontSize: CGFloat

    var weight: Font.Weight

    var foreground: Color

    var background: Color

    @Environment(\.self) var environment

    init(foregroundColor: Color, backgroundColor: Color, fontSize: CGFloat, relativeTo textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular) {
        self.foreground = foregroundColor
        self.background = backgroundColor
        self._fontSize = .init(wrappedValue: fontSize, relativeTo: textStyle)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        let contrast = Font.APCAContrastTarget(for: fontSize, weight: weight)

        content.foregroundStyle(foreground.minimumContrast(contrast, over: background))
    }
}

public extension View {
    @available(iOS 18.0, *)
    func apcaForeground(
        _ foreground: Color,
        over background: Color,
        fontSize: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(
            APCADerivedForegroundColor(
                foregroundColor: foreground,
                backgroundColor: background,
                fontSize: fontSize,
                relativeTo: textStyle,
                weight: weight
            )
        )
    }

    @available(iOS 26.0, *)
    func apcaForeground<Foreground: ShapeStyle, Background: ShapeStyle>(
        _ foreground: Foreground,
        over background: Background
    ) -> some View where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
        foregroundStyle(foreground.minimumContrast(over: background))
    }
}

extension Color.Resolved {
    public static func APCAContrast(text: Color.Resolved, background: Color.Resolved) -> Float {
        let text = text.over(background)

        func softClamp(_ luminance: Float) -> Float {
            guard luminance < 0.022 else { return luminance }

            return pow(0.022 - luminance, 1.414) + luminance
        }

        var Ybackground = softClamp(background.apcaLuminance)
        var Ytext = softClamp(text.apcaLuminance)

        if Ybackground > Ytext {
            Ybackground = pow(Ybackground, 0.56)
            Ytext = pow(Ytext, 0.57)
        } else {
            Ybackground = pow(Ybackground, 0.65)
            Ytext = pow(Ytext, 0.62)
        }

        let contrast = (Ybackground - Ytext) * 1.14

        if abs(contrast) < 0.1 {
            return 0
        } else if contrast > 0 {
            return 100 * (contrast - 0.027)
        } else {
            return 100 * (contrast + 0.027)
        }
    }

    static func over(a: Self, b: Self) -> Self {
        let i = (1 - a.opacity)

        let opacity = a.opacity + b.opacity * i

        return .init(
            red:     (a.red   * a.opacity + b.red   * b.opacity * i) / opacity,
            green:   (a.green * a.opacity + b.green * b.opacity * i) / opacity,
            blue:    (a.blue  * a.opacity + b.blue  * b.opacity * i) / opacity,
            opacity: opacity
        )
    }

    var apcaLuminance: Float {
        pow(red,   2.4) * 0.2126729 +
        pow(green, 2.4) * 0.7151522 +
        pow(blue,  2.4) * 0.0721750
    }

    func over(_ background: Color.Resolved) -> Color.Resolved {
        .over(a: self, b: background)
    }
}



#Preview("Over") {
    @Previewable @State var a = Color.Resolved(red: 0.6, green: 0.3, blue: 0.4, opacity: 0.5)
    @Previewable @State var b = Color.Resolved(red: 0.2, green: 0.2, blue: 1.0, opacity: 0.2)

    HStack(spacing: 0) {
        Color(a.over(b).over(.init(red: 1, green: 1, blue: 1)))

        Color(a).background(Color(b), in: .rect).background(.white)
    }
}

#Preview("Test Values") {
    let rgb2color: (UInt) -> Color.Resolved = { rgb in
        Color.Resolved(
            red:   Float((rgb >> 16) & 0xFF) / 255,
            green: Float((rgb >> 8) & 0xFF) / 255,
            blue:  Float((rgb >> 0) & 0xFF) / 255
        )
    }

    let example: (Color.Resolved, Color.Resolved) -> some View = { a, b in
        HStack {
            Group {
                Color(a)
                Color(b)
                VStack(alignment: .trailing) {
                    Text(Color.Resolved.APCAContrast(text: a, background: b), format: .number)
                    Text(Color.Resolved.APCAContrast(text: b, background: a), format: .number)
                }
                .frame(maxWidth: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .monospacedDigit()
    }

    example(rgb2color(0x888888), rgb2color(0xffffff))

    example(rgb2color(0x000000), rgb2color(0xaaaaaa))

    example(rgb2color(0x112233), rgb2color(0xddeeff))

    example(rgb2color(0x112233), rgb2color(0x444444))
}

@available(iOS 18.0, *)
#Preview("Modifier") {
    @Previewable @State var fontSize: CGFloat = 16
    @Previewable @State var fontWeightIndex: Int = 3

    @Previewable @State var text: Color = .yellow
    @Previewable @State var background: Color = .orange

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

        ForEach([Color.white, .orange, .black], id: \.self) { background in
            HStack {
                let colors = [Color.green, .yellow, .orange, .pink, .purple, .blue]
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
                            case .thin:       Text("Thin")
                            case .light:      Text("Light")
                            case .regular:    Text("Regular")
                            case .medium:     Text("Medium")
                            case .semibold:   Text("Semibold")
                            case .bold:       Text("Bold")
                            case .heavy:      Text("Heavy")
                            case .black:      Text("Black")
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
                    HStack {

                    }
                }
            }
        }
        .padding(.horizontal)

        Spacer().frame(height: 44)

    }
}

@available(iOS 18.0, *)
#Preview("ShapeStyle") {
    @Previewable @State var foreground: Color = .red
    @Previewable @State var background: Color = .blue
    @Previewable @State var contrast: Float = 90

    GroupBox {
        Slider(value: $contrast, in: 0 ... 100)

        HStack {
            ColorPicker("Foreground", selection: $foreground)
            ColorPicker("Background", selection: $background)
        }
    }
    .padding()

    Circle()
        .fill(foreground.minimumContrast(contrast, over: background))
        .frame(width: 44, height: 44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
}

#Preview("Interpolating Font.Weight") {
    @Previewable @State var weight: CGFloat = 0

    GroupBox {
        Slider(value: $weight, in: -1 ... 1)

        Text("A")
            .font(.system(size: 100, weight: .init(value: weight)))
    }
    .padding()
}

@available(iOS 26.0, *)
#Preview("Readme") {
    HStack {
        Text("Hello World")

        Text("What's Up?!")
            .fontWeight(.black)
    }
    .foregroundStyle(Color.pink.minimumContrast(over: Color.primary))
    .padding()
    .background(.primary)
}
