//
//  URL+Extensions.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

extension URL {
	/// For `myapp://conversation?id=123`, `host` is `conversation`.
	/// For `myapp://v1/conversation?id=123`, `host` is `v1` and first path component is
	/// `conversation`.
	var pathParts: [String] {
		pathComponents.filter { $0 != "/" }
	}
}
