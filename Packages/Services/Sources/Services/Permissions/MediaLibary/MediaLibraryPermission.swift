//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation
import MediaPlayer

public extension Permission {
    static var mediaLibrary: MediaLibraryPermission {
        MediaLibraryPermission()
    }
}

public class MediaLibraryPermission: Permission {
    public var kind: PermissionKind {
        .mediaLibrary
    }

    public var status: PermissionStatus {
        switch MPMediaLibrary.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }

    public func request(completion: @escaping @Sendable () -> Void) {
        MPMediaLibrary.requestAuthorization { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
