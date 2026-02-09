//
//  EdgeInsets+Extensions.swift
//  XUI
//
//  Created by Aung Ko Min on 28/9/25.
//

import SwiftUI

public extension EdgeInsets {
	var horizontal: CGFloat {
		get {
			leading + trailing
		} set {
			leading = newValue / 2
			trailing = newValue / 2
		}
	}

	var vertical: CGFloat {
		get {
			top + bottom
		} set {
			top = newValue / 2
			bottom = newValue / 2
		}
	}
}
