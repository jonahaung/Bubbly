//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI
import XUI

public struct PermissionView: View {
    let permission: any Permission
    @State private var reload = 0

    public init(_ permissionKind: PermissionKind) {
        permission = permissionKind.permission
    }

    public var body: some View {
		Label {
			HStack(spacing: 4) {
				Text(permission.kind.name)
				Spacer()
				Button {
					handleButtonAction()
				} label: {
					Text(permission.ctaText)
						.font(.footnote)
				}
			}
			Text(permission.kind.description)
				.italic()
		} icon: {
			IconView {
				Image(systemName: permission.kind.imageName)
			}
			.foregroundStyle(RandomShapeStyle.style(for: permission.kind.name))
		}
        .id(reload)
    }

    private func handleButtonAction() {
        if permission.denied {
            permission.openSettingPage()
        } else if permission.notDetermined {
            permission.request {
                MainActor.assumeIsolated {
                    reload += 1
                }
            }
        } else if permission.authorized {
            permission.openSettingPage()
        }
    }
}
