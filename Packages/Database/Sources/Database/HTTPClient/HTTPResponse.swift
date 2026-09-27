//
//  HTTPResponse.swift
//  Database
//
//  Created by Aung Ko Min on 27/9/26.
//

import Foundation

struct HTTPResponse: Sendable {
    let statusCode: Int
    let headers: [String: String]
    let data: Data
}
