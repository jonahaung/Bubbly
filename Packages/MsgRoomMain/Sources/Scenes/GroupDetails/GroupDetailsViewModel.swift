//
//  GroupDetailsViewModel.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/8/25.
//

import Database
import MediaPicker
import Services
import UIKit

@MainActor
@Observable
public final class GroupDetailsViewModel: ErrorPresenter {
    var group: Database.Group
    var contacts = [Contact]()
    var originalGroup: Database.Group
    var pickedPhoto: PickedPhoto?
    var isLoading = false

    init(group: Database.Group) {
        self.group = group
        originalGroup = group
        contacts = group.members
            .compactMap { ContactStore.shared.contact(for: $0) }
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    var hasChanges: Bool {
        group != originalGroup || pickedPhoto != nil || group.members.sorted() != originalGroup.members.sorted()
    }

    func reset() {
        group = originalGroup
        pickedPhoto = nil
        contacts = group.members
            .compactMap { ContactStore.shared.contact(for: $0) }
    }

    func uploadImage(image: UIImage) async throws -> URL {
        setLoading(true)
        UIApplication.shared.endEditing()
        let uid = originalGroup.uid
        let imageUploader = ImageUploadingService()
        let url = try await imageUploader.uploadImage(
            image,
            size: .init(width: 100, height: 100),
            to: .group(groupID: uid)
        )
        return url
    }

    func applyUpdate() async throws {
        setLoading(true)
        UIApplication.shared.endEditing()
        try await Task.sleep(seconds: 1)
        let group = group
		try await Store.shared.groupStore?
            .updateAndSave(uid: originalGroup.uid) { model in
                model.update(from: group)
            }
        try await FirestoreRepo.add(group, collectionPath: .groups, documentID: group.uid)
        setLoading(false)
    }
}
