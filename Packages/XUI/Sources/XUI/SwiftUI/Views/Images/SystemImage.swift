//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

public struct SystemImage: View {
    private let systemName: String
    private let size: CGFloat?
    private var color: Color = .init(uiColor: .secondaryLabel)

    public init(systemName: String, _ _size: CGFloat? = nil) {
        self.systemName = systemName
        size = _size
    }

    public init(_ symbol: SFSafeSymbols.SFSymbol, _ size: CGFloat? = nil) {
        self.init(systemName: symbol.rawValue, size)
    }

    public var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(square: size ?? UIFont.systemFontSize)
    }

    public func relativeColor(_ value: Color) -> Self {
        map { $0.color = value }
    }
}
