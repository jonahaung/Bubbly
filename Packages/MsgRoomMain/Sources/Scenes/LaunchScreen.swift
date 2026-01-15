//
//  LaunchScreen.swift
//  Bubbly
//
//  Created by Aung Ko Min on 17/8/25.
//

import Core
import FirebaseMessaging
import Services
import SwiftUI
import XUI

struct LaunchScreen: View {
	@Environment(AppLauncher.self) private var launcher
	var body: some View {
		VStack {
			Spacer()

			Button {
				launcher.startEvaluate()
			} label: {
				Image(systemName: "bubble.left.and.text.bubble.right.fill")
					.resizable()
					.scaledToFit()
					.frame(width: 80)
					.symbolEffect(.wiggle.byLayer.up)
					.symbolColorRenderingMode(.flat)
					.fontWeight(.ultraLight)
			}
			.buttonStyle(.plain)
			Spacer()
		}
		.symbolRenderingMode(.hierarchical)
		.padding(.horizontal, 90)
		.statusBarHidden()
		.onAppear(after: Platform.isSimulator ? 1 : 0.5) {
			launcher.startEvaluate()
		}
	}
}

struct Logo: View {
	@State private var angle = -60.0
	@State private var scale = 0.25
	@State private var breatheIn = true
	@State private var breatheOut = false
	let flowerColor = Color(#colorLiteral(red: 0.3084011078, green: 0.5618229508, blue: 0, alpha: 1))

	var body: some View {
		ZStack {
			ForEach(0 ..< 6) { item in
				Image(systemName: "viewfinder")
				// Image(systemName: "seal")
				// Image(systemName: "rhombus.fill")
				// Image(systemName: "shield")
				// Image(systemName: "pentagon")
					.font(.system(size: 150))
					.foregroundColor(flowerColor)
					.offset(y: -80)
					.rotationEffect(.degrees(Double(item)) * angle)
					.scaleEffect(CGFloat(scale))
					.hueRotation(.degrees(angle))
					.blendMode(.difference)
					.animation(.easeInOut(duration: 4).delay(0.75).repeatForever(autoreverses: true), value: scale)
					.onAppear {
						angle = 60.0
						scale = 1
					}
			}
		}
	}
}
