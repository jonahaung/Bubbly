//
//  MsgCellDisplayData.swift
//  Services
//
//  Created by Aung Ko Min on 22/9/25.
//

import SwiftUI
import Database
import XUI
import Core

public struct MsgCellDisplayData: Conformable {
	public var content: MsgCellDisplayData.ContentDisplay
	public init(msg: Message) {
		content = MsgCellDisplayData.ContentDisplay.create(from: msg)
	}
}
public extension MsgCellDisplayData {
	enum ContentDisplay: Conformable {
		case text(_ text: String)
		case markdown(_ elements: [MarkdownElement])
		case attachment(_ attachment: Attachment)
		case emoji(_ image: String)
	}
}
public extension MsgCellDisplayData.ContentDisplay {
	static func create(from msg: Message) -> MsgCellDisplayData.ContentDisplay {
		switch msg.msgKind {
		case .markdown:
			let markdowns = MarkdownParser.parse(msg.text)
			return .markdown(markdowns)
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
