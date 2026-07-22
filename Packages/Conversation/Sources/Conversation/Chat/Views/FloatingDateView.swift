//  FloatingDateView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI

struct FloatingDateView: View {
    @Environment(ChatManager.self) private var manager
    private var dateString: String? { manager.presentation.state.dateText }
    var body: some View {
        if let dateString {
            VStack {
                Text(dateString)
                    .font(.system(size: UIFont.smallSystemFontSize, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
            .geometryGroup()
            .equatable(by: dateString)
        }
    }
}
