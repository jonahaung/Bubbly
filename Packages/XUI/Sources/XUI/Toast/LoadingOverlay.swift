//  LoadingOverlay.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Pow
import SwiftUI

public struct LoadingOverlay: View {
    public init() {}

    public var body: some View {
        LoadingIndicator(22)
            .transition(.movingParts.anvil)
    }
}
