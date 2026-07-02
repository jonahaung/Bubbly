//  SomeActor.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

@globalActor
public struct SomeActor {
    public actor SomeActor {}
    public static let shared: SomeActor = .init()
}
