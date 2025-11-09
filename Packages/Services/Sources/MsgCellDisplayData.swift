//
//  MsgCellDisplayData.swift
//  Services
//
//  Created by Aung Ko Min on 22/9/25.
//

import Core
import Database
import SwiftUI
import XUI

public struct MsgCellDisplayData: Conformable {
    public var content: MsgCellDisplayData.ContentDisplay
    public init(msg: Message) {
        content = MsgCellDisplayData.ContentDisplay.create(from: msg)
    }
}

public extension MsgCellDisplayData {
    enum ContentDisplay: Conformable {
        case text(_ text: String)
        case markdown(_ attributedString: AttributedString)
        case attachment(_ attachment: Attachment)
        case emoji(_ image: String)
    }
}

public extension MsgCellDisplayData.ContentDisplay {
    static func create(from msg: Message) -> MsgCellDisplayData.ContentDisplay {
        switch msg.msgKind {
        case .markdown:
            if let markdowns = try? AttributedString(markdown: msg.text) {
                return .markdown(markdowns)
            }
            return .text(msg.text)
        case .image, .attachment:
            guard let attachment = msg.attachment else {
                return .text(msg.text)
            }
            return .attachment(attachment)
        default:
            return .text(msg.text)
        }
    }
}
