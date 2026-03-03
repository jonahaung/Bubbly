//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct PermissionView: View {
    let permission: any Permission
    @State private var reload = 0

    public init(_ permissionKind: PermissionKind) {
        permission = permissionKind.permission
    }

    public var body: some View {
        HStack(alignment: .center) {
            Image(systemName: permission.kind.imageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(square: 24)
                .padding(8)

            Text(permission.kind.name + "\n" + permission.kind.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .italic()

            Spacer()

            Button {
                handleButtonAction()
            } label: {
                Text(permission.ctaText)
                    .font(.footnote)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.borderless)
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
