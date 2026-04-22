//  CellSpacer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI
import Database

struct CellSpacer: View, @MainActor Equatable {
    var body: some View {
        Spacer()
            .frame(height: ChatLayoutConstants.Cell.sectionSpacing)
    }

    static func == (_: Self, _: Self) -> Bool {
        true
    }
}
