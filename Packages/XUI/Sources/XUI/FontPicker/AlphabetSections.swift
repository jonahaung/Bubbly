//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct AlphabetSections<Destination: View>: View {
    let families: [String]
    let alphabets: [Character]
    let textSize: CGFloat
    let onPick: (String) -> Void
    let onNavigate: (String, [String]) -> Destination

    var body: some View {
        ForEach(alphabets, id: \.self) { initial in
            let familiesWithInitial = families
                .filter { $0.first?.lowercased() == initial.lowercased() }
            if !familiesWithInitial.isEmpty {
                Section(header: Text(String(initial.uppercased()))) {
                    ForEach(familiesWithInitial, id: \.self) { family in
                        let fonts = UIFont.fontNames(forFamilyName: family)
                        if let firstFont = fonts.first {
                            Group {
                                if fonts.count == 1 {
                                    Button {
                                        onPick(firstFont)
                                    } label: {
                                        Text(family)
                                    }
                                } else {
                                    NavigationLink {
                                        onNavigate(family, fonts)
                                    } label: {
                                        Text(family)
                                    }
                                }
                            }
                            .foregroundStyle(.black)
                            .font(Font.custom(firstFont, size: textSize))
                        }
                    }
                }
            }
        }
    }
}
