import SwiftUI
import XUI

struct AudioRecorderButton: View {
    private let source = ChatComposer.Source.audio

    @State private var recorder = AudioRecorder()
    @Environment(ChatComposer.self) private var composer
    
    var body: some View {
        CustomButton {
            handleAction()
        } label: {
            Image(systemName: systemImageName)
                .resizable()
                .scaledToFit()
                .frame(square: 20)
                .padding()
                .frame(square: 38)
                .background(Color.appPrimary, in: .circle)
                .foregroundStyle(recorder.isRecording ? .red : .primary)
                .symbolRenderingMode(.multicolor)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var systemImageName: String {
        if recorder.isRecording {
            "stop.fill"
        } else if recorder.recordingURL != nil {
            "waveform.circle.fill"
        } else {
            source.systemImageName
        }
    }

    private var accessibilityLabel: String {
        if recorder.isRecording {
            "Stop audio recording"
        } else if recorder.recordingURL != nil {
            "Preview audio recording"
        } else {
            source.localizedName
        }
    }

    private func handleAction() {
        if recorder.isRecording {
            _ = recorder.stop()
        } else if let recordingURL = recorder.recordingURL {
            composer.selection = [recordingURL]
            composer.lookUp = recordingURL
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            do {
                try await recorder.start()
            } catch {
                
            }
        }
    }
}
