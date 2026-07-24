//
//  ErrorHandler.swift
//  XUI
//
//  Created by Aung Ko Min on 24/7/26.
//

import SwiftUI

@MainActor
public struct ErrorHandler: Sendable {
    let callback: @Sendable (Error) -> Void

    public func handle(error: Error) {
        callback(error)
    }

    public func callAsFunction<R>(_ block: @Sendable () throws -> R?) -> R?
    where R: Sendable {
        do {
            return try block()
        } catch {
            handle(error: error)
            return nil
        }
    }

    public func callAsFunction<R>(_ block: @Sendable () async throws -> R?)
        async -> R? where R: Sendable
    {
        do {
            return try await block()
        } catch {
            handle(error: error)
            return nil
        }
    }
}

extension EnvironmentValues {
    @Entry public var errorHandler: ErrorHandler = .init(callback: {
        fatalError("Unhandled error: \($0)")
    })
}

public struct ErrorHandlingModifier: ViewModifier {
    @State var error: String?

    public func body(content: Content) -> some View {
        content.environment(
            \.errorHandler,
            ErrorHandler { value in
                Task { @MainActor in
                    error = value.localizedDescription
                }
            }
        )
        .alert(
            item: $error,
            content: { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error),
                    dismissButton: .default(Text("OK"))
                )
            }
        )
    }
}
