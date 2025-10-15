//
//  MediaPickerVideoThumbnil.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 2024/04/22.
//

import SwiftUI
import AVFoundation

public struct MediaPickerVideoThumbnil: View {
    struct FramePositionSlider: View {
        @Binding var pos: CMTime

        let duration: CMTime

        @State private var position: Double = .zero

        let step: Double = 0.1

        var body: some View {
            VStack(alignment: .trailing) {
                Slider(value: $position, in: 0...1.0)
                    .onChange(of: position) { _, newValue in
                        pos = CMTimeMakeWithSeconds(duration.seconds*newValue, preferredTimescale: duration.timescale)
                    }
                Text("\(pos.seconds, specifier: "%.1f")/\(duration.seconds, specifier: "%.1f")")
            }
        }
    }

    let asset: AVAsset
    private let imageGenerator: AVAssetImageGenerator

    // @State private var frameImage: UIImage? = nil
    @State private var duration: CMTime?
    @State private var time: CMTime = .zero

    @Binding private var frameImage: UIImage?

    public init(asset: AVAsset, image: Binding<UIImage?>) {
        self.asset = asset
        self.imageGenerator = AVAssetImageGenerator(asset: asset)
        self.imageGenerator.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 30)
        self.imageGenerator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 30)
        self._frameImage = image
    }

    private func updateFrame(atTime time: CMTime) {
        var actualTime: CMTime = .zero
        if let cgImage = try? self.imageGenerator.copyCGImage(at: time, actualTime: &actualTime) {
            frameImage = UIImage(cgImage: cgImage)
        }
    }

    public var body: some View {
        ZStack {
            if let duration {
                FramePositionSlider(pos: $time, duration: duration)
                    .onChange(of: time) { _, newTime in
                        updateFrame(atTime: newTime)
                    }
            } else {
                ProgressView("Loading")
            }
        }.task {
            do {
                let duration = try await asset.load(.duration)
                self.duration = duration
                self.updateFrame(atTime: time)
            } catch {
                /// Error
            }
        }
    }
}
