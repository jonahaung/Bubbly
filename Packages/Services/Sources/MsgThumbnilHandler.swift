//
//  MsgThumbnilHandler.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import SwiftUI
import Core
import Database
import XUI
import ImageLoader

public enum MsgThumbnilHandler {
	public static func saveImage(_ uiImage: UIImage, msgID: String) async throws {
		let mediaManager = MediaManager.shared
		let data = try mediaManager.createData(from: uiImage)
		let thumbData = try await mediaManager.createThumbnil(from: uiImage)
		try mediaManager.save(msgID, data: data, .png)
		try mediaManager.saveThumbnil(msgID, data: thumbData, .png)
    }
}
