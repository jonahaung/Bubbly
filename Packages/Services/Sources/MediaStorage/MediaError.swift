//
//  MediaError.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation

// MARK: - MediaError Enum
public enum MediaError: Error {
	case fileNotFound
	case invalidPath
	case fileCreationFailed
	case fileDeletionFailed
	case fileSizeCalculationFailed
}
