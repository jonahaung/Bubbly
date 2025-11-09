//
//  TestingViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 8/11/25.
//

import Foundation
import XUI

@MainActor
@Observable
final class TestingViewModel {
    var text = String()

    deinit {
        Log("Deinit")
    }
}
