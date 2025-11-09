//
//  XAttachment.swift
//
//
//  Created by Aung Ko Min on 18/7/23.
//

import Foundation

public struct XAttachment: Hashable, Codable, Identifiable, Sendable, Equatable {
    public enum XAttachmentKind: String, Codable, CaseIterable, Sendable {
        case photo, video
    }

    public var id: String { urlString }
    public var urlString: String
    public var type: XAttachmentKind
    public var identifier: String?
    public var url: URL? { URL(string: urlString) }
    public var isLocalURL: Bool { url?.isFileURL == true }
    public var initialImageData: Data?

    public init(url: String, type: XAttachmentKind, identifier: String? = nil, initialImageData: Data? = nil) {
        urlString = url
        self.type = type
        self.identifier = identifier
        self.initialImageData = initialImageData
    }
}
