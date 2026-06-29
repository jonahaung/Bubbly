//  ToastHolderView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct ToastHolderView: View {
    let toast: Toast
    @State private var isPressing: Bool = false
    var body: some View {
        ModalOverlay(
            toast.style.alignment,
            from: toast.style.edge,
            allowsBackgroundTap: false
        ) {
            ZStack {
                toast.node.eraseToNode()
                    .lineHeight(.multiple(factor: 1.1))
                    .opacity(isPressing ? 0.3 : 1)
                    .padding(16)
                    ._onButtonGesture(pressing: { pressing in
                        isPressing = pressing
                    }, perform: {
                        toast.action?()
                        ToastPresenter.shared.dismiss()
                    })
            }
            .sensoryFeedback(.selection, trigger: isPressing, condition: { oldValue, newValue in
                oldValue == false && newValue == true
            })
            .glassEffect(.regular.tint(.white), in: .containerRelative)
            .runningBorder(lineWidth: 1.5, cornerRadius: 7)
            .containerShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 4)
        }
    }
}
