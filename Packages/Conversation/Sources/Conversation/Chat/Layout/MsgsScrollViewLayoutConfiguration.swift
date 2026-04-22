//
//  MsgsScrollViewLayoutConfiguration.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/4/26.
//

import Database
import SwiftUI

struct MsgsScrollViewLayoutConfiguration {

    init(
        spacing: CGFloat,
        contentInsets: EdgeInsets,
        screenSize: CGSize
    ) {
        self.spacing = spacing
        self.contentInsets = contentInsets
        self.screenSize = screenSize
    }

    let spacing: CGFloat
    let contentInsets: EdgeInsets
    let screenSize: CGSize
    var boundsWidth: CGFloat {
        screenSize.width
    }
    
    var bubbleWidthRatio: CGFloat {
        screenSize.height > screenSize.width ? 0.95 : 0.7
    }
}
