import SwiftUI

extension RedactionReasons {
    public static let shimmer: RedactionReasons = .init(rawValue: 1 << 8)
    public static let blurred: RedactionReasons = .init(rawValue: 1 << 9)
    public static let thumbnail: RedactionReasons = .init(rawValue: 1 << 10)
}

public struct RedactionConfiguration: Sendable {
    public var shape: PlaceholderShape
    public var animationDuration: TimeInterval
    public var shimmerColors: [Color]
    
    public static let `default` = RedactionConfiguration(
        shape: .roundedRectangle(12),
        animationDuration: 1.5,
        shimmerColors: [.gray.opacity(0.3), .gray.opacity(0.6), .gray.opacity(0.3)]
    )
    
    public init(
        shape: PlaceholderShape = .roundedRectangle(12),
        animationDuration: TimeInterval = 1.5,
        shimmerColors: [Color] = [.gray.opacity(0.3), .gray.opacity(0.6), .gray.opacity(0.3)]
    ) {
        self.shape = shape
        self.animationDuration = animationDuration
        self.shimmerColors = shimmerColors
    }
}

public struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path

    public init<S: Shape & Sendable>(_ shape: S) {
        self._path = { rect in
            shape.path(in: rect)
        }
    }

    public func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

public enum PlaceholderShape: Sendable {
    case rectangle
    case roundedRectangle(CGFloat)
    case circle
    case capsule
    
    func makeShape() -> AnyShape {
        switch self {
        case .rectangle:
            return AnyShape(Rectangle())
        case .roundedRectangle(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        case .circle:
            return AnyShape(Circle())
        case .capsule:
            return AnyShape(Capsule())
        }
    }
}

public extension View {
    func customRedaction(_ configuration: RedactionConfiguration = .default) -> some View {
        modifier(CustomRedactionModifier(configuration: configuration))
    }
    func redactedWithShimmer(when condition: Bool) -> some View {
        redacted(reason: condition ? .shimmer : [])
    }
    
    func redactedWithBlur(when condition: Bool) -> some View {
        redacted(reason: condition ? .blurred : [])
    }
    
    func redactedAsThumbnail(when condition: Bool) -> some View {
        redacted(reason: condition ? .thumbnail : [])
    }
}

private struct CustomRedactionModifier: ViewModifier {
    @Environment(\.redactionReasons) private var reasons
    let configuration: RedactionConfiguration
    
    func body(content: Content) -> some View {
        if reasons.isEmpty {
            content
        } else if reasons.contains(.shimmer) {
            content
                .modifier(ShimmerPlaceholder(configuration: configuration))
        } else if reasons.contains(.blurred) {
            content
                .modifier(BlurredPlaceholder())
        } else if reasons.contains(.thumbnail) {
            content
                .modifier(ThumbnailPlaceholder(configuration: configuration))
        } else {
            content
        }
    }
}

private struct ShimmerPlaceholder: ViewModifier {
    let configuration: RedactionConfiguration
    @State private var offset: CGFloat = -1
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay(overlayView)
            .onAppear {
                startAnimation()
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            size = geometry.size
                        }
                }
            )
    }
    
    @ViewBuilder
    private var overlayView: some View {
        configuration.shape.makeShape()
            .fill(Color.gray.opacity(0.2))
            .overlay(shimmerGradient)
            .clipShape(configuration.shape.makeShape())
    }
    
    private var shimmerGradient: some View {
        LinearGradient(
            colors: configuration.shimmerColors,
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: offset * max(size.width, size.height))
        .animation(
            .linear(duration: configuration.animationDuration).repeatForever(autoreverses: false),
            value: offset
        )
    }
    
    private func startAnimation() {
        offset = 2
    }
}

private struct BlurredPlaceholder: ViewModifier {
    @State private var isBlurred = true
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isBlurred ? 10 : 0)
            .animation(.easeInOut(duration: 0.3), value: isBlurred)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isBlurred = false
                }
            }
    }
}

private struct ThumbnailPlaceholder: ViewModifier {
    let configuration: RedactionConfiguration
    @State private var isThumbnail = true
    
    func body(content: Content) -> some View {
        ZStack {
            if isThumbnail {
                configuration.shape.makeShape()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            } else {
                content
            }
        }
        .animation(.spring(), value: isThumbnail)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isThumbnail = false
            }
        }
    }
}

public extension EnvironmentValues {
    @Entry var redactionConfiguration = RedactionConfiguration.default
}
