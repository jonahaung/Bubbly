//  PContact.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData
import Foundation

@Model
public final class PContact: ContactRepresentable, SendableTransformable, Codable {
    
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
    
    private enum CodingKeys: String, CodingKey {
        case uid
        case name
        case mobile
        case photoURL
        case pushToken
        case publicKeyString
    }

    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uid = try container.decode(String.self, forKey: .uid)
        let name = try container.decode(String.self, forKey: .name)
        let mobile = try container.decode(String.self, forKey: .mobile)
        let photoURL = try container.decode(String.self, forKey: .photoURL)
        let pushToken = try container.decode(String.self, forKey: .pushToken)
        let publicKeyString = try container.decode(String.self, forKey: .publicKeyString)
        self.init(
            uid: uid,
            name: name,
            mobile: mobile,
            photoURL: photoURL,
            pushToken: pushToken,
            publicKeyString: publicKeyString
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(name, forKey: .name)
        try container.encode(mobile, forKey: .mobile)
        try container.encode(photoURL, forKey: .photoURL)
        try container.encode(pushToken, forKey: .pushToken)
        try container.encode(publicKeyString, forKey: .publicKeyString)
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
