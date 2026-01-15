//
//  Platform.swift
//  XUI
//
//  Created by Aung Ko Min on 14/1/26.
//

import Foundation

public enum Platform {
	public static var isSimulator: Bool {
		#if targetEnvironment(simulator)
		return true
		#else
		return false
		#endif
	}
}
