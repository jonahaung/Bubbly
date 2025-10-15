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
	
	public init(msg: MsgSnapshot) {
		content = MsgCellDisplayData.ContentDisplay.create(from: msg)
	}
	
}

public extension MsgCellDisplayData {
	
//	final
//	class PrefetchData: Conformable {
//		public static func == (lhs: MsgCellDisplayData.PrefetchData, rhs: MsgCellDisplayData.PrefetchData) -> Bool {
//			lhs.thumbnail == rhs.thumbnail
//		}
//		
//		public func hash(into hasher: inout Hasher) {
//			thumbnail.hash(into: &hasher)
//		}
//		
//		public typealias ID = MsgSnapshot
//		public let attachmentID: String
//		public let thumbnail: UIImage?
//		
//		public init(thumbnail: UIImage?, id: String) {
//			self.attachmentID = id
//			self.thumbnail = thumbnail
//		}
//		public static func performFetch(for msg: Database.MsgSnapshot) -> MsgCellDisplayData.PrefetchData? {
//			let mediaManager = MediaManager.shared
//			let prefetchData: MsgCellDisplayData.PrefetchData? = {
//				if let id = msg.attachment?.uid, mediaManager.thumbnilExist(for: id, .png) {
//					let thumbnilPath = mediaManager.thumbnilPath(for: id, .png)
//					if let image = UIImage(contentsOfFile: thumbnilPath) {
//						return MsgCellDisplayData.PrefetchData(thumbnail: image, id: id)
//					}
//				}
//				return nil
//			}()
//
//			return prefetchData
//		}
//	}
	enum ContentDisplay: Conformable {
		case text(_ text: String)
		case markdown(_ elements: [MarkdownElement])
		case attachment(_ attachment: Attachment)
		case emoji(_ image: String)
	}
	
	enum AttachmentDisplay: Conformable {
		case localImage(_ attachment: Attachment)
		case remoteImage(_ attachment: Attachment)
		case imageUploading(_ attachment: Attachment)
		case link(_ attachment: Attachment)
	}
}

public extension MsgCellDisplayData.ContentDisplay {
	static func create(from msg: MsgSnapshot) ->  MsgCellDisplayData.ContentDisplay {
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
