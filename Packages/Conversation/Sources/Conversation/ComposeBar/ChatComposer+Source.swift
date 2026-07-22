//  ChatComposer+Source.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Foundation

// MARK: - ChatComposer.Source

extension ChatComposer {
    enum Source: String, Hashable, Identifiable, Equatable, CaseNameReflectable {
        var id: Self {
            self
        }

        case camera, liary, audio, document, machineImag, emoji

        static let mediaSources: [Self] = [.camera, .liary, .audio]
        static let utilitySources: [Self] = [.document, .machineImag, .emoji]
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

    var keepsMenuOpen: Bool {
        switch self {
        case .emoji:
            true
        case .camera, .liary, .audio, .document, .machineImag:
            false
        }
    }

    var usesInlinePanel: Bool {
        switch self {
        case .emoji, .camera, .liary, .document, .machineImag:
            true
        case .audio:
            false
        }
    }
}
