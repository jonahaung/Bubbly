import Core
import Foundation
import Shared

public extension HTTPClient {

    @discardableResult
    func updateContact<T: ContactRepresentableSendable>(_ model: T) async throws -> T {
        let request = Request.ContactUpdate(modal: model)
        return try await executor.send(request)
    }

    func contact<T: ContactRepresentableSendable>(uid: String) async throws -> T? {
        let request = Request.ContactGet<T>(uid: uid)
        return try await executor.send(request)
    }

    func lookupContacts(mobileNumbers: [String]) async throws -> [Contact] {
        let request = Request.ContactLookup(
            mobileNumbers: mobileNumbers
        )
        return try await executor.send(request)
    }
}
