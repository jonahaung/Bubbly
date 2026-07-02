//
//  PaginationState.swift
//  Database
//
//  Created by Aung Ko Min on 20/5/26.
//

public struct PaginationState: Hashable, Sendable {
    public let conID: String
    public let pageSize: Int
    public var lastMsgID: String?
    public let firstMsgID: String?
    public var totalMsgsCount: Int
    
    public init(conID: String, pageSize: Int, lastMsgID: String? = nil, firstMsgID: String?, totalMsgsCount: Int) {
        self.conID = conID
        self.pageSize = pageSize
        self.lastMsgID = lastMsgID
        self.firstMsgID = firstMsgID
        self.totalMsgsCount = totalMsgsCount
    }
}
