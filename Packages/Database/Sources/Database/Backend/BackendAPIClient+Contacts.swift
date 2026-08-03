import Core
import Foundation

public extension BackendAPIClient {
    @discardableResult
    func upsertContact(_ model: any ContactRepresentableSendable) async throws -> Contact {
        let data = try await upsertContactResponse(for: model)
        return try executor.decode(Contact.self, from: data)
    }

    func contact(userID: String) async throws -> Contact? {
        let userID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userID.isEmpty, userID.count <= 128 else {
            throw BackendAPIError.invalidRequest("The user identifier is invalid.")
        }
        guard let data = try await executor.send(
            method: "GET",
            path: ["v1", "contacts", userID],
            allowsNotFound: true
        ), !data.isEmpty else {
            return nil
        }
        return try executor.decode(Contact.self, from: data)
    }

    func lookupContacts(mobileNumbers: [String]) async throws -> [Contact] {
        var seen = Set<String>()
        let uniqueNumbers = mobileNumbers.filter { seen.insert($0).inserted }
        guard uniqueNumbers.allSatisfy(Self.isE164) else {
            throw BackendAPIError.invalidRequest("Every mobile number must use E.164 format.")
        }
        guard !uniqueNumbers.isEmpty else {
            return []
        }

        var contacts: [Contact] = []
        contacts.reserveCapacity(uniqueNumbers.count)
        for startIndex in stride(from: 0, to: uniqueNumbers.count, by: 500) {
            let endIndex = min(startIndex + 500, uniqueNumbers.count)
            let request = ContactLookupRequest(mobileNumbers: Array(uniqueNumbers[startIndex ..< endIndex]))
            let data = try await executor.requiredResponse(
                method: "POST",
                path: ["v1", "contacts", "lookup"],
                body: .data(try executor.encode(request)),
                contentType: "application/json"
            )
            contacts.append(contentsOf: try executor.decode([Contact].self, from: data))
        }
        return contacts
    }

    private static func isE164(_ value: String) -> Bool {
        guard value.count >= 9, value.count <= 16, value.first == "+" else {
            return false
        }
        let digits = value.dropFirst()
        return digits.first != "0"
            && digits.unicodeScalars.allSatisfy { (48 ... 57).contains($0.value) }
    }

    internal func upsertContactResponse(
        for model: any ContactRepresentableSendable
    ) async throws -> Data {
        let body = ProfileUpdateRequest(model)
        guard body.name.trimmingCharacters(in: .whitespacesAndNewlines).count <= 100,
              body.mobile.isEmpty || Self.isE164(body.mobile),
              body.pushToken.count <= 4_096,
              body.publicKeyString.count <= 8_192 else {
            throw BackendAPIError.invalidRequest("The contact contains invalid values.")
        }
        return try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "profile"],
            body: .data(try executor.encode(body)),
            contentType: "application/json"
        )
    }
}
