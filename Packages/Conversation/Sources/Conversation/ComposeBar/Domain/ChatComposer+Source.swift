// © 2026 Aung Ko Min

import Database
import Foundation
import SwiftUI
import XUI

// MARK: - ChatComposer.Source

extension ChatComposer {
    enum Source: String, Hashable, Identifiable, Equatable, CaseNameReflectable {
        var id: Self {
            self
        }

        case camera, liary, audio, document, machineImag, emoji
    }
}

extension ChatComposer.Source {
    var systemImageName: String {
        switch self {
        case .audio:
            "microphone.and.signal.meter.fill"
        case .machineImag:
            "apple.intelligence"
        case .liary:
            "photo.stack.fill"
        case .camera:
            "camera.viewfinder"
        case .document:
            "text.document"
        case .emoji:
            "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .emoji:
            Color(.systemPink)
        case .audio:
            Color(.orange)
        case .machineImag:
            Color(.systemPurple)
        case .liary:
            Color(.systemBlue)
        case .camera:
            Color(.systemBlue)
        case .document:
            Color(.systemTeal)
        }
    }
}
