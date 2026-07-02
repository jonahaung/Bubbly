//  Binding++.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@MainActor
public extension Binding {

    func safeBinding<T>(defaultValue: T) -> Binding<T> where Value == T? {
        .init { [defaultValue] in
            wrappedValue ?? defaultValue
        } set: { [self] newValue in
            wrappedValue = newValue
        }
    }

    func trySafeBinding<T>() -> Binding<T>? where Value == T? {
        guard let wrappedValue else {
            return nil
        }

        return Binding<T> { [wrappedValue] in
            wrappedValue
        } set: { [self] newValue in
            self.wrappedValue = newValue
        }
    }
}
