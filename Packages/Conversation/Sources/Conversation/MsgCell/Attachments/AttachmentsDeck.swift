//
//  AttachmentsDeck.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/3/26.
//

import Database
import SwiftUI
import XUI

struct AttachmentsDeck<Content: View>: View {
	
    let items: [Attachment]
    let alignment: HorizontalAlignment
    let content: (Attachment) -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .offset(x: offsetX(for: index), y: offsetY(for: index))
                    .rotationEffect(
                        .degrees(rotation(for: index)),
                        anchor: alignment == .trailing ? .leading : .trailing
                    )
                    .zIndex(zIndex(for: index))
            }
        }
		.equatable(by: items)
    }

    private var xSpacing: CGFloat {
        items.count > 1 ? 20.0 : 0
    }

    private var ySpacing: CGFloat {
        items.count > 1 ? 10.0 : 0
    }

    private func zIndex(for index: Int) -> CGFloat {
        items.count.cgFloat - index.cgFloat
    }

    private func offsetX(for index: Int) -> CGFloat {
        let base = xSpacing
        let signed = alignment == .trailing ? -base : base
        return signed * index.cgFloat
    }

    private func offsetY(for index: Int) -> CGFloat {
        -(index.cgFloat * ySpacing)
    }

    private func rotation(for index: Int) -> CGFloat {
        let idx = index.cgFloat
        let degree = items.count > 3 ? 4.0 : 6.0
        let signed = alignment == .trailing ? -degree : degree
        return signed * idx
    }

    func scale(for index: Int) -> CGFloat {
        guard items.count > 1 else { return 1.0 }
        return 1.0 - (0.1 * index.cgFloat)
    }

    func shadow(for index: Int) -> Color {
        let idx = Double(index)
        let progress = 1.0 - abs(items.count.double - idx)
        let opacity = 0.5 * progress
        return .black.opacity(opacity)
    }
}
