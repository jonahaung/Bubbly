//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class PContact: ContactRepresentable, SendableTransformable {
    @Attribute(.unique)
    public var uid: String
    public var name: String
    public var mobile: String
    public var photoURL: String
    public var pushToken: String
    public var publicKeyString: String

    init(
        uid: String,
        name: String,
        mobile: String,
        photoURL: String,
        pushToken: String,
        publicKeyString: String
    ) {
        self.uid = uid
        self.name = name
        self.mobile = mobile
        self.photoURL = photoURL
        self.pushToken = pushToken
        self.publicKeyString = publicKeyString
    }
}

public extension PContact {
    func merge(from source: any ContactRepresentable) {
        name = mergedString(name, from: source.name)
        mobile = mergedString(mobile, from: source.mobile)
        photoURL = mergedString(photoURL, from: source.photoURL)
        pushToken = mergedString(pushToken, from: source.pushToken)
        publicKeyString = mergedString(publicKeyString, from: source.publicKeyString)
    }

    func update(from item: Contact) {
        name = mergedString(name, from: item.name)
        mobile = mergedString(mobile, from: item.mobile)
        photoURL = mergedString(photoURL, from: item.photoURL)
        pushToken = mergedString(pushToken, from: item.pushToken)
        publicKeyString = mergedString(publicKeyString, from: item.publicKeyString)
    }
}

public extension PContact {
    convenience init(from item: Contact) {
        self.init(
            uid: item.id,
            name: item.name,
            mobile: item.mobile,
            photoURL: item.photoURL,
            pushToken: item.pushToken,
            publicKeyString: item.publicKeyString
        )
    }

    func toSendable() -> Contact {
        Contact(
            uid: uid,
            name: name,
            mobile: mobile,
            photoURL: photoURL,
            pushToken: pushToken,
            publicKeyString: publicKeyString
        )
    }
}
