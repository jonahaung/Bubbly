//
//  SwiftUIView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/2/26.
//

import SwiftUI
import XUI
import Core
import Database
import Services

struct Playground: View {
	@State private var showModal = false
	let text = Lorem.random()
	var body: some View {
		List {

			Button("Show modal") {
				showModal = true
			}
			Button("Show Toast") {
				ToastPresenter.show(Lorem.random())
			}
			Button("Show Loading") {
				Loading.show(true)
			}
			Label(text, systemImage: "bubble.right")
		}
		.navigationTitle("Playgound")
		.overlay {
			if showModal {
				ModalOverlay(.top, from: .top) {
					HighlightedTextDemo()
//					Text(Lorem.random())
						.padding()
						.background(.thickMaterial, in: .containerRelative)
				} onClose: {
					showModal = false
				}
			}
		}
	}
}
