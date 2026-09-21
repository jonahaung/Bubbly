// © 2026 Aung Ko Min

import AVFoundation
import Foundation

public extension Permission {
    static var microphone: MicrophonePermission {
        MicrophonePermission()
    }
}

// MARK: - MicrophonePermission

public final class MicrophonePermission: Permission {
    public var kind: PermissionKind {
        .microphone
    }

    public var status: PermissionStatus {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return .authorized
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return .authorized
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        }
    }

    public func request(completion: @escaping @Sendable () -> Void) {
        if #available(iOS 17.0, *) {
            // iOS 17+: request via AVAudioApplication (static function)
            AVAudioApplication.requestRecordPermission { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
