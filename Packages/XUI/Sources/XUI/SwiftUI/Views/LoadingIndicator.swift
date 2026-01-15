//
//  LoadingIndicator.swift
//  BmCamera
//
//  Created by Aung Ko Min on 28/3/21.
//

import SwiftUI

public struct LoadingIndicator: View {
    public init() {}
    public var body: some View {
        ProgressView()
            .flexible(.horizontal)
            .tint(Color.secondary)
    }
}
