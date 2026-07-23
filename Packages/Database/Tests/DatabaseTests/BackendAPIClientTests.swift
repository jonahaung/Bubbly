@testable import Database
import Foundation
import Testing

@Suite("Backend API Client")
struct BackendAPIClientTests {
    @Test("Builds an authenticated contact request and decodes the response")
    func contactRequest() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 200, headers: [:], data: contactData))
        ])
        let client = try makeClient(transport: transport)

        let contact = try await client.contact(userID: "user/one")
        let requests = await transport.requests

        #expect(contact?.uid == "user-one")
        #expect(requests.count == 1)
        #expect(requests[0].url?.absoluteString == "http://localhost:8080/v1/contacts/user%2Fone")
        #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(requests[0].timeoutInterval == 5)
    }

    @Test("Refreshes the access token once after an unauthorized response")
    func refreshesToken() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 401, headers: [:], data: Data())),
            .response(.init(statusCode: 200, headers: [:], data: contactData))
        ])
        let tokenProvider = TokenProvider()
        let configuration = try configuration()
        let client = BackendAPIClient(
            configuration: configuration,
            transport: transport,
            accessTokenProvider: { forceRefresh in
                await tokenProvider.token(forceRefresh: forceRefresh)
            }
        )

        _ = try await client.contact(userID: "user-one")

        #expect(await tokenProvider.refreshValues == [false, true])
        #expect(await transport.requests.count == 2)
    }

    @Test("Retries a transient server failure")
    func retriesTransientFailure() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 503, headers: ["retry-after": "0"], data: Data())),
            .response(.init(statusCode: 200, headers: [:], data: contactData))
        ])
        let client = try makeClient(transport: transport, retryCount: 1)

        _ = try await client.contact(userID: "user-one")

        #expect(await transport.requests.count == 2)
    }

    @Test("Returns nil for an allowed missing resource")
    func missingContact() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 204, headers: [:], data: Data()))
        ])
        let client = try makeClient(transport: transport)

        #expect(try await client.contact(userID: "missing") == nil)
    }

    @Test("Preserves a structured server rejection")
    func serverRejection() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(
                statusCode: 400,
                headers: [:],
                data: Data(#"{"reason":"Invalid profile","error":true}"#.utf8)
            ))
        ])
        let client = try makeClient(transport: transport)

        await #expect(throws: BackendAPIError.rejected(statusCode: 400, message: "Invalid profile")) {
            try await client.currentProfile()
        }
    }

    @Test("Maps a cancelled URL request to task cancellation")
    func cancellation() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [.urlError(.cancelled)])
        let client = try makeClient(transport: transport)

        await #expect(throws: CancellationError.self) {
            try await client.currentProfile()
        }
    }

    @Test("Rejects invalid contact input before transport")
    func invalidContactInput() async throws {
        let transport = MockBackendHTTPTransport(outcomes: [])
        let client = try makeClient(transport: transport)

        await #expect(throws: BackendAPIError.invalidRequest("Every mobile number must use E.164 format.")) {
            try await client.lookupContacts(mobileNumbers: ["5551234"])
        }
        #expect(await transport.requests.isEmpty)
    }

    @Test("Rejects insecure production configuration")
    func insecureConfiguration() throws {
        #expect(throws: BackendAPIError.insecureConfiguration) {
            try BackendAPIConfiguration(baseURL: #require(URL(string: "http://example.com")))
        }
    }

    @Test("Fetches every group page using an encoded cursor")
    func groupPagination() async throws {
        let firstPage = Data(
            #"{"items":[{"uid":"group-one","name":"Friends","createdDate":"2026-07-23T00:00:00Z","photoURL":null,"members":["owner","member"],"createdBy":"owner"}],"nextCursor":"group/one"}"#.utf8
        )
        let secondPage = Data(#"{"items":[],"nextCursor":null}"#.utf8)
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 200, headers: [:], data: firstPage)),
            .response(.init(statusCode: 200, headers: [:], data: secondPage))
        ])
        let client = try makeClient(transport: transport)

        let groups = try await client.groups(pageSize: 25)
        let requests = await transport.requests

        #expect(groups.map(\.uid) == ["group-one"])
        #expect(requests.count == 2)
        #expect(requests[0].url?.query == "limit=25")
        #expect(requests[1].url?.query == "limit=25&after=group/one")
    }

    @Test("Rejects a repeated group pagination cursor")
    func repeatedGroupCursor() async throws {
        let page = Data(#"{"items":[],"nextCursor":"same"}"#.utf8)
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 200, headers: [:], data: page)),
            .response(.init(statusCode: 200, headers: [:], data: page))
        ])
        let client = try makeClient(transport: transport)

        await #expect(throws: BackendAPIError.invalidResponse) {
            try await client.groups()
        }
        #expect(await transport.requests.count == 2)
    }

    @Test("Upserts a group without trusting client-owned creation metadata")
    func groupUpsert() async throws {
        let response = Data(
            #"{"uid":"group-one","name":"Friends","createdDate":"2026-07-23T00:00:00Z","photoURL":"https://example.com/group.png","members":["member","owner"],"createdBy":"owner"}"#.utf8
        )
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 200, headers: [:], data: response))
        ])
        let client = try makeClient(transport: transport)
        let group = Group(
            uid: "group-one",
            name: "Friends",
            createdDate: .distantPast,
            photoURL: "https://example.com/group.png",
            members: ["owner", "member"],
            createdBy: "untrusted-client-value"
        )

        let saved = try await client.upsertGroup(group)
        let request = try #require(await transport.requests.first)
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(saved.createdBy == "owner")
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.absoluteString == "http://localhost:8080/v1/groups/group-one")
        #expect(object["createdBy"] == nil)
        #expect(object["createdDate"] == nil)
        #expect(object["name"] as? String == "Friends")
    }

    @Test("Sends an encrypted push notification through the backend")
    func pushNotification() async throws {
        let response = Data(
            #"{"results":[{"recipientUserID":"recipient-one","messageID":"message-one","failureCode":null},{"recipientUserID":"recipient-two","messageID":null,"failureCode":"fcm_send_failed"}]}"#.utf8
        )
        let transport = MockBackendHTTPTransport(outcomes: [
            .response(.init(statusCode: 200, headers: [:], data: response))
        ])
        let client = try makeClient(transport: transport)

        let successfulRecipientIDs = try await client.sendPushNotifications(
            messagesByRecipientUserID: [
                "recipient-one": "encrypted-one",
                "recipient-two": "encrypted-two"
            ],
            title: "New message",
            body: "Hello",
            conversationID: "conversation",
            deepLink: "bubbly://conversation/one"
        )
        let request = try #require(await transport.requests.first)
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(successfulRecipientIDs == Set(["recipient-one"]))
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "http://localhost:8080/v1/push-notifications")
        let recipients = try #require(object["recipients"] as? [[String: Any]])
        #expect(recipients.count == 2)
        #expect(recipients[0]["userID"] as? String == "recipient-one")
        #expect(recipients[0]["messageContent"] as? String == "encrypted-one")
        #expect(object["conversationID"] as? String == "conversation")
    }

    private var contactData: Data {
        Data(
            #"{"uid":"user-one","name":"Taylor","mobile":"+6591234567","photoURL":"","pushToken":"push","publicKeyString":"key"}"#.utf8
        )
    }

    private func configuration(retryCount: Int = 0) throws -> BackendAPIConfiguration {
        try BackendAPIConfiguration(
            baseURL: #require(URL(string: "http://localhost:8080")),
            requestTimeout: 5,
            retryPolicy: .init(
                maximumRetryCount: retryCount,
                initialDelay: .zero,
                maximumDelay: .zero
            ),
            allowsInsecureHTTP: true
        )
    }

    private func makeClient(
        transport: MockBackendHTTPTransport,
        retryCount: Int = 0
    ) throws -> BackendAPIClient {
        BackendAPIClient(
            configuration: try configuration(retryCount: retryCount),
            transport: transport,
            accessTokenProvider: { _ in "token" }
        )
    }
}

private actor MockBackendHTTPTransport: BackendHTTPTransport {
    enum Outcome: Sendable {
        case response(BackendHTTPResponse)
        case urlError(URLError.Code)
    }

    private(set) var requests: [URLRequest] = []
    private var outcomes: [Outcome]

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func data(for request: URLRequest) async throws -> BackendHTTPResponse {
        try nextResponse(for: request)
    }

    func upload(for request: URLRequest, fromFile _: URL) async throws -> BackendHTTPResponse {
        try nextResponse(for: request)
    }

    private func nextResponse(for request: URLRequest) throws -> BackendHTTPResponse {
        requests.append(request)
        guard !outcomes.isEmpty else {
            throw URLError(.badServerResponse)
        }
        switch outcomes.removeFirst() {
        case let .response(response):
            return response
        case let .urlError(code):
            throw URLError(code)
        }
    }
}

private actor TokenProvider {
    private(set) var refreshValues: [Bool] = []

    func token(forceRefresh: Bool) -> String {
        refreshValues.append(forceRefresh)
        return forceRefresh ? "fresh" : "stale"
    }
}
