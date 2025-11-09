//
//  MsgRecipient.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/4/24.
//

import SwiftUI
import XUI

public enum MsgRecipient: Int, Codable, Sendable, Hashable, CaseIterable {
	case send
	case receive
	case none
}
