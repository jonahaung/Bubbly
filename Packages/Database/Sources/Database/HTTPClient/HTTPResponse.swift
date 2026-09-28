//  HTTPResponse.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

struct HTTPResponse: Sendable {
    let statusCode: Int
    let headers: [String: String]
    let data: Data
}
