//
//  DemoRow.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 16/2/26.
//

import SwiftUI

import SwiftUI

struct RecyclingDemoView: View {

	let rows = (0..<10_000).map { $0 }

	var body: some View {
		RecyclingScrollingLazyView(
			rowIDs: rows
		) { id in
			DemoRow(id: id)
		}
		.background(.windowBackground)
	}
}

struct DemoRow: View {

    let id: Int
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Row \(id)")
                .font(.headline)

            Text(lorem(for: id))
                .font(.body)

            TextField("Type something", text: $text)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func lorem(for id: Int) -> String {
        let repeatCount = (id % 5) + 1
        return String(repeating: "Dynamic height content. ", count: repeatCount)
    }
}
