//
//  Optional+.swift
//
//
//  Created by Aung Ko Min on 10/6/23.
//

import SwiftUI

/// Optional
public extension Optional {
	var forceUnwrapped: Wrapped! {
		if let value = self {
			return value
		}
		fatalError()
	}
}

public extension Optional where Wrapped: Collection {
	var isNilOrEmpty: Bool {
		self?.isEmpty ?? true
	}
}

public extension String? {
	var str: String {
		self ?? ""
	}

	var bindable: Binding<String> {
		if let unwrapped = self {
			.constant(unwrapped)
		} else {
			.constant("")
		}
	}
}
