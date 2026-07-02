// © 2026 Aung Ko Min

import Photos

public extension Permission {
    static var photoLibrary: PhotoLibraryPermission {
        PhotoLibraryPermission()
    }
}

// MARK: - PhotoLibraryPermission

public final class PhotoLibraryPermission: Permission {
    public var kind: PermissionKind {
        .photoLibrary
    }

    public var fullAccessUsageDescriptionKey: String? {
        "NSPhotoLibraryUsageDescription"
    }

    public var addingOnlyUsageDescriptionKey: String? {
        "NSPhotoLibraryAddUsageDescription"
    }

    public var status: PermissionStatus {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .limited: return .authorized
        @unknown default: return .denied
        }
    }

    public func request(completion: @escaping @Sendable () -> Void) {
        PHPhotoLibrary.requestAuthorization {
            _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
