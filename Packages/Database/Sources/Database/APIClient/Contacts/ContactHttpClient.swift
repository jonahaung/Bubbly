//  ContactHttpClient.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Shared
import Foundation

public actor ContactHttpClient {

    public static let shared: ContactHttpClient = .init()

    let client: HTTPClient = .shared

    @discardableResult
    public func updateContact<T: ContactRepresentableSendable>(_ model: T) async throws
        -> T
    {
        let request = Request.ContactUpdate(modal: model)
        return try await client.executor.send(request)
    }

    public func contact<T: ContactRepresentableSendable>(uid: String) async throws -> T? {
        let request = Request.ContactGet<T>(uid: uid)
        return try await client.executor.send(request)
    }

    public func lookupContacts(mobileNumbers: [String]) async throws -> [Contact] {
        let request = Request.ContactLookup(
            mobileNumbers: mobileNumbers
        )
        return try await client.executor.send(request)
    }

    public func uploadProfilePhoto<T: ContactRepresentableSendable>(data: Data, contentType: String) async throws -> T {
        let request = try Request.ContactUpdateProfilePhoto<T>(
            mdata: data,
            contentType: contentType
        )
        return try await client.executor.send(request)
    }

    public func uploadProfilePhoto<T: ContactRepresentableSendable>(fileURL: URL, contentType: String) async throws -> T
    {
        let request = try Request.ContactUpdateProfilePhoto<T>(
            fileURL: fileURL,
            contentType: contentType
        )
        return try await client.executor.send(request)
    }
}
