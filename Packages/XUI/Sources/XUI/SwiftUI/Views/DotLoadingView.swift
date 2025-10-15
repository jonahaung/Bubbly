//
//  DotLoadingView.swift
//  XUI
//
//  Created by Aung Ko Min on 02/02/23.
//

import SwiftUI

public struct DotLoadingView: View {

    @State private var showCircle1 = false
    @State private var showCircle2 = false
    @State private var showCircle3 = false

    public
    init(showCircle1: Bool = false, showCircle2: Bool = false, showCircle3: Bool = false) {
        self.showCircle1 = showCircle1
        self.showCircle2 = showCircle2
        self.showCircle3 = showCircle3
    }

    public var body: some View {
        HStack {
            Circle()
                .opacity(showCircle1 ? 1 : 0)
            Circle()
                .opacity(showCircle2 ? 1 : 0)
            Circle()
                .opacity(showCircle3 ? 1 : 0)
        }
        .foregroundColor(.gray.opacity(0.5))
        .onAppear { performAnimation() }
    }

    func performAnimation() {
        let animation = Animation.easeInOut(duration: 0.4)
        withAnimation(animation) {
            self.showCircle1 = true
            self.showCircle3 = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                self.showCircle2 = true
                self.showCircle1 = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(animation) {
                self.showCircle2 = false
                self.showCircle3 = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.performAnimation()
        }
    }
}
