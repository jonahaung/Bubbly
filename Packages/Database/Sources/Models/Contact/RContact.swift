//
//  RContact.swift
//  Database
//
//  Created by Aung Ko Min on 1/11/25.
//

import XUI

public struct RContact: ContactRepresentable {
    public let uid: String
    public var name: String
    public let mobile: String
    public var photoURL: String
    public var pushToken: String
    public var publicKeyString: String
}
