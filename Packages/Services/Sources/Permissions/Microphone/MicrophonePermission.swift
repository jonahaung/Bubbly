//
//  MicrophonePermission.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import AVFoundation
import Foundation

public extension Permission {
    static var microphone: MicrophonePermission {
        MicrophonePermission()
    }
}

public class MicrophonePermission: Permission {
    public var kind: PermissionKind { .microphone }

    public var status: PermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    public func request(
        completion: @escaping @Sendable () -> Void
    ) {
        AVAudioSession.sharedInstance().requestRecordPermission {
            _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
