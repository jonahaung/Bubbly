//
//  TestingView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 8/11/25.
//

import SwiftUI
import MsgRoomMain
import XUI

struct TestingView: View {

	@State private var viewModel = TestingViewModel()

    var body: some View {
		ScrollView(.vertical) {
			VStack {
				ForEach((0...100), id: \.self) { _ in
					Text(Lorem.random)
				}
			}.containerRelativeFrame([.horizontal])
		}
		.scrollDismissesKeyboard(.immediately)
		.safeAreaBar(edge: .bottom, spacing: 0) {

		}
		.navigationTitle("Testing")
    }
}

#Preview {
    TestingView()
}
