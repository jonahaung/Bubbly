// © 2026 Aung Ko Min

import Foundation
import UIKit

// MARK: - Permission

public protocol Permission {
    var kind: PermissionKind { get }
    var status: PermissionStatus { get }
    func request(completion: @escaping @Sendable () -> Void)
}

public extension Permission {
    var authorized: Bool {
        status == .authorized
    }

    var denied: Bool {
        status == .denied
    }

    var notDetermined: Bool {
        status == .notDetermined
    }

    var debugName: String {
        kind.name
    }

    var localisedName: String {
        kind.name
    }

    var ctaText: String {
        switch status {
        case .authorized: "Allowed"
        case .denied: "Settings"
        case .notDetermined: "Allow"
        case .notSupported: "Not Supported"
        }
    }

    func openSettingPage() {
        DispatchQueue.main.async {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsUrl) else
            {
                return
            }

            UIApplication.shared.open(settingsUrl)
        }
    }
}
