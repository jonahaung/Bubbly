//  APIRequest.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Foundation

protocol APIRequest {

    associatedtype Response: Decodable

    var version: API.Version { get }
    var path: API.Path { get }
    var endPaths: [String] { get }
    var method: HTTPMethod { get }
    var contentType: String? { get }
    var body: HTTPRequestBody? { get }

    var queryItems: [URLQueryItem] { get }
    var allowsNotFound: Bool { get }
    var acceptsEmptyResponse: Bool { get }
    func responseWhenNotFound() throws -> Response
}

extension APIRequest {

    var version: API.Version { .init(rawValue: API.Version.current) ?? .v1 }
    var contentType: String? { "application/json" }
    var body: HTTPRequestBody? { nil }

    var queryItems: [URLQueryItem] { [] }
    var allowsNotFound: Bool { false }
    var acceptsEmptyResponse: Bool { false }
    func responseWhenNotFound() throws -> Response { throw HTTPError.invalidResponse }
}

extension APIRequest {
    var paths: [String] {
        [version.rawValue, path.rawValue] + endPaths
    }
}

enum Request {}
