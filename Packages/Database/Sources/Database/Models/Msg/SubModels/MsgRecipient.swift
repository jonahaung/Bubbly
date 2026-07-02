//  MsgRecipient.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import SwiftUI

public enum MsgRecipient: Int, Codable, Sendable, Hashable {
    case outgoing
    case incoming
    case system
}
