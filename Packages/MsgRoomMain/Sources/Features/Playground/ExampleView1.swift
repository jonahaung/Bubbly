//
//  ExampleView1.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 20/2/26.
//

import SwiftUI

struct ExampleView1: View {
    @Namespace var ns
    @State private var flag = false
    let colors: [Color] = [.green, .blue]
    
    var body: some View {
		ZStack {
            ScrollView {
                ForEach(0..<100) { idx in
                    RoundedRectangle(cornerRadius: 8).fill(colors[idx%2]).frame(height: 30)
                        .overlay(Text("Idx = \(idx)").foregroundColor(.white))
                        .matchedGeometryEffect(id: idx, in: ns, anchor: .trailing, isSource: true)
                        .padding(.horizontal, 10)
                }
            }

            
            Circle().fill(Color.yellow)
                .frame(width: 30, height: 30)
                .matchedGeometryEffect(id: 1000, in: ns, properties: .position, anchor: .trailing, isSource: true)
                .offset(x: 10)
                .matchedGeometryEffect(id: 9, in: ns, properties: .position, anchor: .leading, isSource: false)

            Circle().fill(Color.red)
                .frame(width: 30, height: 30)
                .offset(x: 10)
                .matchedGeometryEffect(id: 1000, in: ns, properties: .position, anchor: .leading, isSource: false)

            Spacer()
        }
        .frame(width: 300, height: 200)
        .border(Color.gray)
    }
}
