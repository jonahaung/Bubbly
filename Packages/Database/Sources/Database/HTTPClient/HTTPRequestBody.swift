//  HTTPRequestBody.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

enum HTTPRequestBody: Sendable {
    typealias Model = any Encodable & Sendable

    case data(Data)
    case file(URL)
    case encodable(Model)
}
