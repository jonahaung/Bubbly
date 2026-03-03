//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

public struct ImageGeneratingView: View {
    @State private var isDrawing: Bool = false

    public init(isDrawing: Bool) {
        _isDrawing = State(initialValue: isDrawing)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: proxy.size.height / 12))
                    .opacity(0.25)
                    .layoutPriority(1)
                Circle()
                    .trim(from: 0.0, to: isDrawing ? 1.0 : 0.0)
                    .stroke(style: StrokeStyle(
                        lineWidth: proxy.size.height / 12,
                        lineCap: .round,
                        lineJoin: .round
                    ))
                    .rotationEffect(Angle(degrees: -90))
                    .animation(
                        .easeOut.speed(0.01).repeatForever(autoreverses: false),
                        value: isDrawing
                    )
                    .onAppear {
                        isDrawing.toggle()
                    }

                HStack(alignment: .bottom, spacing: -(proxy.size.width / 4)) {
                    VStack {
                        Image(systemSymbol: .circleFill)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(isDrawing ? 0.5 : 1)
                            .offset(x: isDrawing ? 0 : proxy.size.width)
                            .animation(
                                .easeInOut.speed(0.5).repeatForever(autoreverses: true),
                                value: isDrawing
                            )
                        Image(systemSymbol: .triangleshapeFill)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(y: isDrawing ? 1 : 0.5, anchor: .bottom)
                            .animation(
                                .easeOut.speed(0.5).repeatForever(autoreverses: true),
                                value: isDrawing
                            )
                    }
                    Image(systemSymbol: .triangleshapeFill)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(y: isDrawing ? 1 : 0.5, anchor: .bottom)
                        .animation(
                            .easeInOut.speed(0.5).repeatForever(autoreverses: true),
                            value: isDrawing
                        )
                }
                .scaleEffect(0.6)
            }
            .phaseAnimator([false, true]) { content, generating in
                content
                    .transaction { txn in
                        // Keep implicit animations driven by the `generating` phase updates
                        txn.animation = nil
                    }
                    .onChange(of: generating) { _, newValue in
                        // Mirror the phase into our existing `isDrawing` state so current
                        // animations keep working
                        isDrawing = newValue
                    }
            } animation: { _ in
                // Drive the phase changes at a steady pace
                .linear(duration: 1.0).repeatForever(autoreverses: true)
            }
            .onAppear {
                // Ensure animations start in previews and at runtime
                isDrawing = true
            }
        }
    }
}

#Preview {
    ImageGeneratingView(isDrawing: true)
        .preferredColorScheme(.dark)
}
