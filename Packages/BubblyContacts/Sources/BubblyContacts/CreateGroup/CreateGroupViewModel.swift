// © 2026 Aung Ko Min

import Foundation
import Core
import Database
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class CreateGroupViewModel {
    var groupName: String = ""
    var selection: [Contact] = []
    var pickedPhoto: PickedPhoto? = nil
    var uploadedURL: URL? = nil
    var isLoading: Bool = false

    var canCreateGroup: Bool {
        !groupName.isEmpty && !selection.isEmpty && pickedPhoto != nil
    }

    func onSelect(contact: Contact) {
        if let index = selection.firstIndex(where: { $0.uid == contact.uid }) {
            selection.remove(at: index)
        } else {
            selection.append(contact)
        }
    }

    func createGroup() async throws {
        let currentUserID = try CurrentUserID.get()
        guard let image = pickedPhoto?.uiImage else {
            throw CreateGroupError.missingPhoto
        }

        setLoading(true)
        defer { setLoading(false) }
        let groupID = await IDGenerator.shared.make()
        let imageUploader = ImageUploadingService()
        let url = try await imageUploader.uploadImage(
            image,
            size: .init(width: 100, height: 100),
            to: .group(groupID: groupID),
        )
        let memberIDs = [currentUserID] + selection.map(\.uid)
        let group = Group(
            uid: groupID,
            name: groupName,
            createdDate: .now,
            photoURL: url.absoluteString,
            members: memberIDs,
            createdBy: currentUserID,
//            theme: .init()
        )
        try await GroupRepo.save(group)
    }

    @MainActor func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}
