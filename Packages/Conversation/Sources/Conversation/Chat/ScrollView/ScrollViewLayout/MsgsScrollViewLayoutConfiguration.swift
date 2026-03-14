//
//  MsgsScrollViewLayoutConfiguration.swift
//  Conversation
//
//  Created by Aung Ko Min on 9/3/26.
//

import SwiftUI

struct MsgsScrollViewLayoutConfiguration: Equatable {
    let spacing: CGFloat
    let contentInsets: EdgeInsets
    var boundsWidth: CGFloat
	let layoutDirection: VerticalEdge
	let additionalTopSpace = CGFloat(50)
	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, layoutDirection: VerticalEdge = .bottom) {
        self.spacing = spacing
        self.contentInsets = contentInsets
		self.boundsWidth = 0
		self.layoutDirection = layoutDirection
    }
}
