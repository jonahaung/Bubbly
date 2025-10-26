//
//  TextAvatarView.swift
//  XUI
//
//  Created by Aung Ko Min on 6/10/24.
//

import SwiftUI

public struct TextAvatarView: View {

    private let text: String
    private let color: Color

    public init(text: String) {
        self.text = text.words().compactMap { $0.first }.prefix(2).map { String($0).uppercased() }.joined()
		self.color = .gray
    }
    public init(fullText: String) {
        self.text = fullText
        self.color = text.color
    }
    public var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(color.gradient)
                .overlay {
                    Text(text)
                        .font(.system(size: geo.size.height * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                }
        }
        .equatable(by: text)
    }
}
