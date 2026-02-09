//
//  UIImage+.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 2024/04/22.
//

import UIKit

extension UIImage {
	convenience init?(contentsOf url: URL) {
		guard let data = try? Data(contentsOf: url) else {
			return nil
		}
		self.init(data: data)
	}
}
