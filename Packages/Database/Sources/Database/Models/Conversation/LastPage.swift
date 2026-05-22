//
//  LastPage.swift
//  Database
//
//  Created by Aung Ko Min on 14/5/26.
//

import Foundation

public struct LastPage: Sendable, Hashable, Codable {
    public let topMsgID: String
    public let bottomMsgID: String
    public let scrollOffsetY: CGFloat
    public let isPotrait: Bool
    
    public init?(topMsgID: String?, bottomMsgID: String?, scrollOffsetY: CGFloat, isPotrait: Bool) {
        guard let topMsgID, let bottomMsgID else { return nil }
        self.topMsgID = topMsgID
        self.bottomMsgID = bottomMsgID
        self.scrollOffsetY = scrollOffsetY
        self.isPotrait = isPotrait
    }
}
