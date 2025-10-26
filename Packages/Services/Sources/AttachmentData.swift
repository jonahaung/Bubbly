//
//  AttachmentData.swift
//  Services
//
//  Created by Aung Ko Min on 20/10/25.
//

import Foundation

public struct AttachmentData: Sendable, Hashable, Equatable {
	public let id: String
	public let data: Data?
	public init(id: String, data: Data?) {
		self.id = id
		self.data = data
	}
}
