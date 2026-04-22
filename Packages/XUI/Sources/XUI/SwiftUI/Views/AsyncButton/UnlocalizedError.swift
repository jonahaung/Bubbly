//  UnlocalizedError.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

struct UnlocalizedError: LocalizedError {
    let errorDescription: String?

    init(error: Error) {
        errorDescription = error.localizedDescription
    }
}
