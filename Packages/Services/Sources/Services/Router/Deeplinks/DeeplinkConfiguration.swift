//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public struct DeeplinkConfiguration: Sendable, Equatable {
    public let scheme: String
    public let supportedVersions: Set<String>
    public let universalLinkHosts: Set<String>
    public let queryValidation: QueryValidationMode

    public init(
        scheme: String,
        supportedVersions: Set<String> = ["v1"],
        universalLinkHosts: Set<String> = [],
        queryValidation: QueryValidationMode = .permissive
    ) {
        self.scheme = scheme
        self.supportedVersions = supportedVersions
        self.universalLinkHosts = universalLinkHosts
        self.queryValidation = queryValidation
    }
}
