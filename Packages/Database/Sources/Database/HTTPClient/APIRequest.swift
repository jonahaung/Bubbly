//
//  APIRequest.swift
//  Database
//
//  Created by Aung Ko Min on 27/9/26.
//

import Foundation
import Shared

protocol APIRequest {
    associatedtype Response: Decodable
    var version: APIPath.Version { get }
    var subPath: APIPath.SubPath { get }
    var endPoint: APIEndPoint { get }
    var paths: [String] { get }
    var method: HTTPMethod { get }
    var contentType: String? { get }
    var body: Encodable? { get }
}

extension APIRequest {
    var version: APIPath.Version { .v1 }
    var contentType: String? { "application/json" }
    var body: Encodable? { nil }

    var paths: [String] {
        [version.rawValue, subPath.rawValue, endPoint.rawValue]
    }
}

enum Request {}
struct EmptyResponse: Decodable {
    init() {}
}
