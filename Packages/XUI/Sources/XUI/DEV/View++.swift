//
//  Untitled.swift
//  XUI
//
//  Created by Aung Ko Min on 9/4/26.
//

import SwiftUI

public extension View {
	func on<Content: View>(_ platforms: Platform..., transform: (Self) -> Content) -> AnyView {
		guard platforms.contains(Platform.current) else { return anyView }
		return transform(self).anyView
	}

	var anyView: AnyView { AnyView(self) }

	func rectReader(_ binding: Binding<CGRect>, in coordinatorSpace: CoordinateSpace = .local) -> some View {
		background(
			GeometryReader { geometry -> Color in
				let rect = geometry.frame(in: coordinatorSpace)
				DispatchQueue.main.async {
					binding.wrappedValue = rect
				}
				return .clear
			}
		)
	}

	func applyBackground(_ color: Color = (.background)) -> some View {
		ZStack {
			color
				.ignoresSafeArea(.all)
			self
		}
	}
}
