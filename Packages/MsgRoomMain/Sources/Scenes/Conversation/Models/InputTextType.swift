//
//  InputTextType.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 2/1/26.
//

import Database
import Foundation

public enum InputTextType: Sendable, Hashable {
	case text, imageGenerator

	public mutating func toggle() {
		switch self {
		case .text:
			self = .imageGenerator
		case .imageGenerator:
			self = .text
		}
	}
}
