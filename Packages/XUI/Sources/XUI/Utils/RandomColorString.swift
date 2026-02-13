import SwiftUI

public extension Color {
	static var random: Color {
		var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
		return random(using: &generator)
	}

	static func random(using generator: inout RandomNumberGenerator) -> Color {
		Color.adaptableColors.randomElement(using: &generator)!
	}

	static func random(_ seed: Int) -> Color {
		var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
		return random(using: &generator)
	}
}

public extension String {
	var color: Color {
		let seed = count
		var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
		return .random(using: &generator)
	}
}
