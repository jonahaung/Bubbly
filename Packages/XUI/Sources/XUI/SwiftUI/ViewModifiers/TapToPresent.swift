//
//  FullScreenPresenting.swift
//  MyBike
//
//  Created by Aung Ko Min on 29/11/21.
//

import SwiftUI

private struct PresentSheetModifier<Destination: View>: ViewModifier {

	@ViewBuilder var destination: (() -> Destination)
	var onDismiss: (() -> Void)?
	@State private var isPresented = false

	public func body(content: Content) -> some View {
		content
			.onTapGesture {
				isPresented = true
			}
			.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
				destination()
			}
	}
}

private struct PresentFullScreenModifier<Destination: View>: ViewModifier {

	@ViewBuilder var destination: (() -> Destination)
	var onDismiss: (() -> Void)?
	@State private var isPresented = false

	public func body(content: Content) -> some View {
		content
			.onTapGesture {
				withTransaction(.withoutAnimation) {
					isPresented = true
				}
			}
			.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
				destination()
			}
	}
}

private struct PresentFullScreenWithTransitionModifier<Destination: View>: ViewModifier {
	let id: String
	@ViewBuilder var destination: (() -> Destination)

	@State private var isPresented = false
	@Namespace private var animation

	public func body(content: Content) -> some View {
		content
			.gesture(
				TapGesture(count: 1).onEnded { _ in
					withTransaction(.init(animation: .linear(duration: 0.2))) {
						isPresented = true
					}
				}
			)
			.matchedTransitionSource(id: id, in: animation)
			.fullScreenCover(
				isPresented: $isPresented
			) {
				destination()
					.statusBarHidden()
					.presentationBackground(.ultraThinMaterial)
					.presentationBackgroundInteraction(.enabled)
					.navigationTransition(.zoom(sourceID: id, in: animation))
			}
	}
}

public extension View {
	func presentSheet<Content: View>(@ViewBuilder content: @escaping () -> Content, onDismiss: sending (() -> Void)? = nil) -> some View {
		ModifiedContent(content: self, modifier: PresentSheetModifier(destination: content, onDismiss: onDismiss))
	}
	func presentFullScreen<Content: View>(@ViewBuilder content: @escaping () -> Content, onDismiss: sending (() -> Void)? = nil) -> some View {
		ModifiedContent(content: self, modifier: PresentFullScreenModifier(destination: content, onDismiss: onDismiss))
	}
	func sheetWithZoomTransition<Destination: View>(id: String = UUID().uuidString, @ViewBuilder destination: @escaping () -> Destination) -> some View {
		ModifiedContent(content: self, modifier: PresentFullScreenWithTransitionModifier(id: id, destination: destination))
	}
}
