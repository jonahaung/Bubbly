import Foundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone access is required to record audio."
        case .recordingFailed:
            "The audio recording could not be started."
        }
    }
}
