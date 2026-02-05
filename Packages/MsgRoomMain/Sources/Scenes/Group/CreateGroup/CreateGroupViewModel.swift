//
//  CreateGroupViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 20/8/25.
//

import Core
import Database
import MediaPicker
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class CreateGroupViewModel {
    var groupName: String = ""
    var selection = [Contact]()
    var pickedPhoto: PickedPhoto?
    var uploadedURL: URL?
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
        guard let currentUserID = currentUserId, let image = pickedPhoto?.uiImage else {
            fatalError()
        }
        setLoading(true)
        let groupID = UUID().uuidString
        let imageUploader = ImageUploadingService()
        let url = try await imageUploader.uploadImage(
            image,
            size: .init(width: 100, height: 100),
            to: .group(groupID: groupID)
        )
        let memberIDs = [currentUserID] + selection.map(\.uid)
        let group = Group(
            uid: groupID,
            name: groupName,
            createdDate: .init(.now),
			photoURL: url.absoluteString,
            members: memberIDs,
            createdBy: currentUserID,
            theme: .init(),
            seenMembers: []
        )
        try await FirestoreRepo.add(group, collectionPath: .groups, documentID: group.uid)
		try await Store.shared.groupStore?.insert(group)
        try await Task.sleep(seconds: 2)
        setLoading(false)
    }

    @MainActor func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}
