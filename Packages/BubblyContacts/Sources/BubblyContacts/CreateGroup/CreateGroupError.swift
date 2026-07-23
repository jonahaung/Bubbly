import Foundation

enum CreateGroupError: Error, LocalizedError {
    case missingPhoto

    var errorDescription: String? {
        "Select a group photo before creating the group."
    }
}
