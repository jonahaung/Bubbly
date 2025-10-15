//
//  RandomColor.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 27/6/24.
//

import SwiftUI

public extension Color {
	static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
	static func random(using generator: inout RandomNumberGenerator) -> Color {
        return Color.adaptableColors.randomElement(using: &generator)!
    }
}

public extension String {
    var color: Color {
        let seed = self.count
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
}
