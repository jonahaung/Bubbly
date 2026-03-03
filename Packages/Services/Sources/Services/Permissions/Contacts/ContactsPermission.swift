//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Contacts
import Foundation

public extension Permission {
    static var contacts: ContactsPermission {
        ContactsPermission()
    }
}

public class ContactsPermission: Permission {
    public var kind: PermissionKind {
        .contacts
    }

    public var status: PermissionStatus {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if #available(iOS 18.0, *), authorizationStatus == .limited {
            return .authorized
        }
        switch authorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .limited: return .denied
        @unknown default: return .denied
        }
    }

    public func request(completion: @escaping @Sendable () -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        })
    }
}
