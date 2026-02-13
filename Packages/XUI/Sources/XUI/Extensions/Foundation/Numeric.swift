import Foundation
import SwiftUI

extension Int: @retroactive Identifiable {
	public var id: Int {
		self
	}
}

public extension Int {
	var cgFloat: CGFloat {
		CGFloat(self)
	}

	var double: Double {
		Double(self)
	}

	var float: Float {
		Float(self)
	}
}

public extension CGFloat {
	var int: Int {
		Int(self)
	}

	var double: Double {
		Double(self)
	}

	var float: Float {
		Float(self)
	}

	var half: CGFloat {
		self / 2
	}

	func rounded(toPlaces places: Int) -> CGFloat {
		guard places >= 0 else { return self }
		let multiplier = pow(10.0, CGFloat(places))
		return (self * multiplier).rounded() / multiplier
	}
}

public extension Float {
	var int: Int {
		Int(self)
	}

	var double: Double {
		Double(self)
	}

	var cgFloat: CGFloat {
		CGFloat(self)
	}
}

public extension CGFloat {
	var scaled: CGFloat {
		UIFontMetrics.default.scaledValue(for: self)
	}
}

public extension Int {
	var scaled: CGFloat {
		UIFontMetrics.default.scaledValue(for: cgFloat)
	}
}
