//  Platform.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public enum Platform: Sendable {
    case macOS
    case iOS
    case tvOS
    case watchOS
    case visionOS

    #if os(macOS)
        static let current = macOS
    #elseif os(iOS)
        static let current = iOS
    #elseif os(tvOS)
        static let current = tvOS
    #elseif os(watchOS)
        static let current = watchOS
    #elseif os(visionOS)
        static let current = visionOS
    #else
        #error("Unsupported platform")
    #endif

    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

// source: https://stackoverflow.com/a/62099616
public extension View {
    /**
     Conditionally apply modifiers depending on the target operating system.

     ```
     struct ContentView: View {
         var body: some View {
             Text("Unicorn")
                 .font(.system(size: 10))
                 .ifOS(.macOS, .tvOS) {
                     $0.font(.system(size: 20))
                 }
         }
     }
     ```
     */
    @ViewBuilder
    func ifPlatform(
        _ operatingSystems: Platform...,
        modifier: (Self) -> some View
    ) -> some View {
        if operatingSystems.contains(Platform.current) {
            modifier(self)
        } else {
            self
        }
    }
}
