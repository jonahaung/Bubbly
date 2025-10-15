//
//  File.swift
//  
//
//  Created by Aung Ko Min on 18/7/23.
//

import SwiftUI

extension EditMode {
    public mutating func toggle() {
        switch self {
            case .inactive:
                self = .active
            case .transient:
                self = .inactive
            case .active:
                self = .inactive
            @unknown default:
                self = .inactive
        }
    }
}
