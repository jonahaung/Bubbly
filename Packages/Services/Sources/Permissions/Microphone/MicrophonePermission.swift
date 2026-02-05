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

public final class MicrophonePermission: Permission {
    public var kind: PermissionKind { .microphone }

    public var status: PermissionStatus {
		let permission = AVAudioSession.sharedInstance().recordPermission
		switch permission {
		case AVAudioSession.RecordPermission.granted:
			return .authorized
		case AVAudioSession.RecordPermission.denied:
			return .denied
		case AVAudioSession.RecordPermission.undetermined:
			return .notDetermined
		@unknown default:
			return .denied
		}
    }

    public func request(
        completion: @escaping @Sendable () -> Void
    ) {
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
