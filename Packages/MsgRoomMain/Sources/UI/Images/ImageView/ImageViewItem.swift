//
//  ImageItemPresentable.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Foundation
import Services

public protocol ImageViewItem: Sendable {
	var url: URL { get }
	var id: String { get }
	var type: MediaType { get }
}
