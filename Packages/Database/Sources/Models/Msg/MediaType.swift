//
//  MediaType.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Foundation

public enum MediaType: Hashable, CaseIterable {
	case png, video, audio, data
	public var fileExtension: String {
		switch self {
		case .png: return ".png"
		case .video: return ".mp4"
		case .audio: return ".m4a"
		case .data:
			return ""
		}
	}
	public var directory: String {
		switch self {
		case .png: return "photos"
		case .video: return "videos"
		case .audio: return "audios"
		case .data:
			return "data"
		}
	}
}
