//
//  MsgCellViewModel.swift
//  Services
//
//  Created by Aung Ko Min on 14/8/25.
//

import Database
import SwiftUI
import XUI

@Observable
public final class MsgCellViewModel: ViewReloadable {

	public private(set) var msg: Message
	public private(set) var displayData: MsgCellDisplayData
    public private(set) var isVisible = false
	public private(set) var layout = MsgCellLayout()
	@ObservationIgnored public let attachment: MsgCellAttachmentViewModel = .init()
	public var reloadID: Int = 0

    public init(_ msg: Message) {
        self.msg = msg
        displayData = .init(msg: msg)
    }

    public func update(with msg: Message) {
        guard self.msg != msg else { return }
        self.msg = msg
        displayData.content = MsgCellDisplayData.ContentDisplay.create(from: msg)
        layoutIfNeeded()
    }

    public func update(layout: MsgCellLayout) {
        guard self.layout != layout else { return }
        self.layout = layout
		layoutIfNeeded()
    }

    public func setVisibility(_ isVisible: Bool) {
        guard self.isVisible != isVisible else { return }
        self.isVisible = isVisible
		layoutIfNeeded()
    }
}

public extension MsgCellViewModel {
    var id: String { msg.uid }
    var isSender: Bool { msg.isSender }
    var foregroundStyle: Color {
        isSender ? .black : .primary
    }

    var horizontalAlignment: HorizontalAlignment {
        isSender ? .trailing : .leading
    }

    func sender() -> Contact? {
        ContactStore.shared.contact(for: msg.senderID)
    }
}

@MainActor
@Observable
public final class MsgCellAttachmentViewModel {
    public var thumbnail: UIImage?
}
