//
//  ImageSize.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Foundation

public protocol ImageSize {
	var width: CGFloat? { get }
	var height: CGFloat? { get }
}
public extension ImageSize {
	var size: CGSize? {
		guard let width, let height else {
			return nil
		}
		return .init(width: width, height: height)
	}
}
