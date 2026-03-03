//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        guard let wrappedValue = wrappedValue else {
            return nil
        }
		
        return Binding<T> { [wrappedValue] in
            wrappedValue
        } set: { [self] newValue in
            self.wrappedValue = newValue
        }
    }
}
