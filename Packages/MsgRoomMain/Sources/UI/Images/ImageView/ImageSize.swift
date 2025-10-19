//
//  ImageSize.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
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
