//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ExampleView1: View {
    @Namespace var namespace
    @State private var flag = false
    let colors: [Color] = [.green, .blue]
    
    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView {
                ForEach(0..<100) { idx in
                    RoundedRectangle(cornerRadius: 8).fill(colors[idx % 2]).frame(height: 30)
                        .overlay(Text("Idx = \(idx)").foregroundColor(.white))
                        .matchedGeometryEffect(
                            id: idx,
                            in: namespace,
                            anchor: .leading,
                            isSource: true
                        )
                }
            }

            Circle().fill(Color.yellow)
                .frame(width: 30, height: 30)
                .matchedGeometryEffect(
                    id: 1000,
                    in: namespace,
                    properties: .position,
                    anchor: .trailing,
                    isSource: true
                )
                .matchedGeometryEffect(id: 9, in: namespace, properties: .position, anchor: .leading, isSource: false)

            Circle().fill(Color.red)
                .frame(width: 30, height: 30)
                .matchedGeometryEffect(id: 1000, in: namespace, properties: .position, anchor: .leading, isSource: false)
        }
        .frame(width: 300)
        .border(Color.gray)
    }
}
