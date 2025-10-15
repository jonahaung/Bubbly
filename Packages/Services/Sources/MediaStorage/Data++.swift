//
//  Data++.swift
//  Services
//
//  Created by Aung Ko Min on 7/3/25.
//

import Foundation

// MARK: - Data Extension
extension Data {
	func write(to path: String, options: Data.WritingOptions = []) throws {
		try self.write(to: URL(fileURLWithPath: path), options: options)
	}
}
