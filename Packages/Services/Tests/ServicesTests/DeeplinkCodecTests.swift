// © 2026 Aung Ko Min

import Foundation
@testable import Services
import Testing

struct DeeplinkCodecTests {
    @Test func profileRoundTripsThroughCustomSchemeURL() throws {
        let codec = DeeplinkCodec.standard
        let url = try #require(codec.url(for: .profile(id: "user-42")))

        #expect(url.absoluteString == "bubbly://profile?id=user-42")
        #expect(try codec.parse(url).get() == .profile(.init(id: "user-42")))
    }

    @Test func conversationAliasParsesToTypedRoute() throws {
        let codec = DeeplinkCodec.standard
        let url = try #require(URL(string: "bubbly://conv?id=con-7"))

        #expect(try codec.parse(url).get() == .conversation(.init(conID: "con-7")))
    }

    @Test func missingRequiredIDFails() throws {
        let codec = DeeplinkCodec.standard
        let url = try #require(URL(string: "bubbly://profile"))

        #expect(codec.parse(url) == .failure(.missingRequiredParameter(route: "profile", name: "id")))
    }

    @Test func strictValidationRejectsUnknownQueryItems() throws {
        let codec = DeeplinkCodec.standard
        let url = try #require(URL(string: "bubbly://conversation?id=con-7&extra=1"))

        #expect(codec.parse(url) == .failure(.unknownQueryItems(route: "conversation", unknown: ["extra"])))
    }
}
