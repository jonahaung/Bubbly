//
//  GroupDetailsViewModel.swift
//  BubblyContacts
//
//  Created by Aung Ko Min on 6/4/26.
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
	var properties: ConversationProperties
    init(group: Database.Group) {
        self.group = group
        originalGroup = group
        contacts = group.members
            .compactMap { ContactsRepository.shared.contact(for: $0) }
		properties = .init(uid: group.uid)
    }
	func task() async {
		properties = await ConversationPropertiesRepo.getOrCreateMain(for: group.uid)
	}
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    var hasChanges: Bool {
        group != originalGroup || pickedPhoto != nil || group.members.sorted() != originalGroup
            .members.sorted()
    }

    func reset() {
        group = originalGroup
        pickedPhoto = nil
        contacts = group.members
            .compactMap { ContactsRepository.shared.contact(for: $0) }
    }

    func uploadImage(image: UIImage) async throws -> URL {
        setLoading(true)
        UIApplication.shared.endEditing()
        let uid = originalGroup.uid
        let imageUploader = ImageUploadingService()
        return try await imageUploader.uploadImage(
            image,
            size: .init(width: 100, height: 100),
            to: .group(groupID: uid)
        )
    }

    func applyUpdate() async throws {
        setLoading(true)
        UIApplication.shared.endEditing()

		let updatedGroup = group
        let originalUID = originalGroup.uid

        try await Task.sleep(seconds: 1)

        try await Store.shared.groupStore?
            .updateAndSave(uid: originalUID) { model in
                model.update(from: updatedGroup)
            }

        try await FirestoreRepo.set(updatedGroup, collectionPath: .groups, documentID: updatedGroup.uid)
        setLoading(false)
    }
}
