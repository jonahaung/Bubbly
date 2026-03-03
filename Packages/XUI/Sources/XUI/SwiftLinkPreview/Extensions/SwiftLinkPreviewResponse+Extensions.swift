//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension SwiftLinkPreviewResponse {
    var dictionary: [String: Any] {
        var responseData: [String: Any] = [:]
        responseData["baseURL"] = baseURL
        responseData["url"] = url
        responseData["finalUrl"] = finalUrl
        responseData["canonicalUrl"] = canonicalUrl
        responseData["title"] = title
        responseData["description"] = description
        responseData["images"] = images
        responseData["image"] = image
        responseData["icon"] = icon
        responseData["video"] = video
        responseData["price"] = price
        return responseData
    }

    enum Key: String {
        case url
        case finalUrl
        case canonicalUrl
        case title
        case description
        case image
        case images
        case icon
        case video
        case baseURL
        case price
    }

    mutating func set(_ value: Any, for key: Key) {
        switch key {
        case .baseURL:
            if let value = value as? String { baseURL = value }
        case .url:
            if let value = value as? URL { url = value }
        case .finalUrl:
            if let value = value as? URL { finalUrl = value }
        case .canonicalUrl:
            if let value = value as? String { canonicalUrl = value }
        case .title:
            if let value = value as? String { title = value }
        case .description:
            if let value = value as? String { description = value }
        case .image:
            if let value = value as? String { image = value }
        case .images:
            if let value = value as? [String] { images = value }
        case .icon:
            if let value = value as? String { icon = value }
        case .video:
            if let value = value as? String { video = value }
        case .price:
            if let value = value as? String { price = value }
        }
    }

    func value(for key: Key) -> Any? {
        switch key {
        case .baseURL:
            baseURL
        case .url:
            url
        case .finalUrl:
            finalUrl
        case .canonicalUrl:
            canonicalUrl
        case .title:
            title
        case .description:
            description
        case .image:
            image
        case .images:
            images
        case .icon:
            icon
        case .video:
            video
        case .price:
            price
        }
    }
}
