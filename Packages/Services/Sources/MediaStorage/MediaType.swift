//
//  MediaType.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation

public enum MediaType: Hashable, CaseIterable {
	case png, video, audio
	var directory: String {
		switch self {
		case .png: return "photo"
		case .video: return "video"
		case .audio: return "audio"
		}
	}

	var fileExtension: String {
		switch self {
		case .png: return "png"
		case .video: return "mp4"
		case .audio: return "m4a"
		}
	}
}
